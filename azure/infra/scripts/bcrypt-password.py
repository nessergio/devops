#!/usr/bin/env python3
import bcrypt, sys, json
pw = sys.argv[1].encode()
hashed = bcrypt.hashpw(pw, bcrypt.gensalt(rounds=10)).decode().replace("$2b$", "$2a$")
print(json.dumps({"hash": hashed}))
