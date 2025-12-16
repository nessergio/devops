sh_command_id=$(aws ssm send-command \
    --instance-ids "$instance" \
    --document-name "AWS-RunShellScript" \
    --comment "Demo run shell script on Linux managed node" \
    --parameters commands=whoami \
    --output text \
    --query "Command.CommandId")

aws ssm list-commands \
    --command-id "$sh_command_id"