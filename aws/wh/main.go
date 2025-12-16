package main

import (
	"encoding/json"
	"errors"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/charmbracelet/log"
	"io"
	"net/http"
	"os"
	"time"
)

const CmdWaitPeriod = 1 * time.Second

func getEnv(key, fallback string) string {
	value, exists := os.LookupEnv(key)
	if !exists {
		value = fallback
	}
	return value
}

func String(v string) *string { return &v }

func getHealth(w http.ResponseWriter, r *http.Request) {
	if _, err := io.WriteString(w, "Healthcheck OK\n"); err != nil {
		log.Errorf("can not write response")
	}
}

type alertDef struct {
	Status       string            `json:"status"`
	Labels       map[string]string `json:"labels"`
	Annotations  map[string]string `json:"annotations"`
	StartsAt     time.Time         `json:"startsAt"`
	EndsAt       time.Time         `json:"endsAt"`
	GeneratorURL string            `json:"generatorURL"`
	Fingerprint  string            `json:"fingerprint"`
}

type msgDef struct {
	Version           string            `json:"version"`
	GroupKey          string            `json:"groupKey"`
	TruncatedAlerts   int               `json:"truncatedAlerts"`
	Status            string            `json:"status"`
	Receiver          string            `json:"receiver"`
	GroupLabels       map[string]string `json:"groupLabels"`
	CommonLabels      map[string]string `json:"commonLabels"`
	CommonAnnotations map[string]string `json:"commonAnnotations"`
	ExternalUrl       string            `json:"externalUrl"`
	Alerts            []alertDef        `json:"alerts"`
}

type ssmClient struct {
	svc *ssm.SSM
	as  *autoscaling.AutoScaling
}

func newSSMClient() *ssmClient {
	var sClient ssmClient
	// Create EWS session with default config
	ewsSession := session.Must(session.NewSession())
	// Create a SSM client from just a session.
	sClient.svc = ssm.New(ewsSession)
	if sClient.svc == nil {
		log.Fatal("can not create SSM client")
	}
	sClient.as = autoscaling.New(ewsSession)
	if sClient.as == nil {
		log.Fatal("can not create AutoScale client")
	}
	return &sClient
}

func (sc *ssmClient) getSomeInstance() string {
	x, err := sc.svc.DescribeInstanceInformation(&ssm.DescribeInstanceInformationInput{})
	if err != nil {
		log.Errorf("error describing instance: %v", err)
	}
	//log.Infof("%+v", x)
	if len(x.InstanceInformationList) == 0 {
		return ""
	}
	return *x.InstanceInformationList[0].InstanceId
}

func (sc *ssmClient) sendCommand(cmd string, instanceId string) string {
	log.Debugf("sending command %s to %s", cmd, instanceId)
	o, err := sc.svc.SendCommand(&ssm.SendCommandInput{
		InstanceIds:  []*string{&instanceId},
		DocumentName: String("AWS-RunShellScript"),
		Parameters:   map[string][]*string{"commands": {&cmd}},
	})
	if err != nil {
		log.Errorf("error sending command: %v", err)
		return "Error"
	}
	cmdId := o.Command.CommandId
	status := *o.Command.Status
	for status == "Pending" || status == "InProgress" {
		time.Sleep(CmdWaitPeriod)
		gci, err2 := sc.svc.GetCommandInvocation(&ssm.GetCommandInvocationInput{
			CommandId:  cmdId,
			InstanceId: &instanceId,
		})
		log.Debugf("output: %s", *gci.StandardOutputContent)
		if err2 != nil {
			log.Errorf("error listing command: %v", err)
			return "Error"
		}
		status = *gci.Status
	}
	log.Debugf("result: %s", status)
	return status
}

func (sc *ssmClient) scaleWorker(delta int64) {
	dasgo, err := sc.as.DescribeAutoScalingGroups(&autoscaling.DescribeAutoScalingGroupsInput{})
	if err != nil || len(dasgo.AutoScalingGroups) == 0 {
		log.Errorf("error describing autoscale groups: %v", err)
	}
	minSize := *dasgo.AutoScalingGroups[0].MinSize
	maxSize := *dasgo.AutoScalingGroups[0].MaxSize
	capacity := *dasgo.AutoScalingGroups[0].DesiredCapacity
	asgName := dasgo.AutoScalingGroups[0].AutoScalingGroupName
	log.Infof("MIN: %d MAX: %d CAP: %d", minSize, maxSize, capacity)
	desiredCapacity := min(capacity+delta, maxSize)
	if delta < 0 {
		desiredCapacity = max(capacity+delta, minSize)
	}
	res, err := sc.as.SetDesiredCapacity(&autoscaling.SetDesiredCapacityInput{
		AutoScalingGroupName: asgName,
		DesiredCapacity:      &desiredCapacity,
	})
	if err != nil {
		log.Errorf("error setting desired capacity: %v", err)
	}
	log.Infof("%+v", res.GoString())
}

func (sc *ssmClient) scaleContainerUp(instanceId string) {
	if sc.sendCommand("su - demo -c 'cd ~/demo/stack-worker && bash scale.sh up'", instanceId) == "Success" {
		log.Info("Scaled successfully!")
	} else {
		log.Warn("Not scaled!")
	}
}

func (sc *ssmClient) scaleContainerDown(instanceId string) {
	if sc.sendCommand("su - demo -c 'cd ~/demo/stack-worker && bash scale.sh down'", instanceId) == "Success" {
		log.Info("Scaled successfully!")
	} else {
		log.Warn("Not scaled!")
	}
}

var sc *ssmClient

func notify(w http.ResponseWriter, r *http.Request) {
	var m msgDef
	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&m); err != nil {
		log.Errorf("Error getting message: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if m.Status == "firing" {
		for _, alert := range m.Alerts {
			log.Infof("Got %s Alert for instance %s: %s",
				alert.Labels["severity"], alert.Labels["instance"], alert.Labels["action"])
			switch alert.Labels["action"] {
			case "container-up":
				log.Info("CONTAINER UP")
				sc.scaleContainerUp(alert.Labels["instance"])
			case "container-down":
				log.Info("CONTAINER DOWN")
				sc.scaleContainerDown(alert.Labels["instance"])
			case "worker-up":
				log.Info("WORKER-UP")
				sc.scaleWorker(1)
			case "worker-down":
				log.Info("WORKER-DOWN")
				sc.scaleWorker(-1)
			default:
				log.Warn("Unknown action")
			}
		}
	}
}

func main() {
	log.SetLevel(log.DebugLevel)
	sc = newSSMClient()
	port := getEnv("PORT", "3000")
	// Specify endpoint handlers
	http.HandleFunc("/health", getHealth)
	http.HandleFunc("/", notify)
	// Serving on specified port using default multiplexer
	log.Infof("Starting server on port %s..", port)
	err := http.ListenAndServe(":"+port, nil)
	if errors.Is(err, http.ErrServerClosed) {
		log.Warnf("server closed: %v", err)
	} else if err != nil {
		log.Warnf("can`t start server: %v", err)
		os.Exit(1)
	}
}
