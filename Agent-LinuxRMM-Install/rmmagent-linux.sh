# EX: Install
#         ./rmmagent-linux.sh install amd64 "https://mesh.rmmtactical.com/meshagents?id=Sd7iQrSbDd%245o2464351FsR6m%24nh3K1D7lnwJWIBn35ad8%40JtRgiyNlvjVACQ%40ebLT5ExtT&installflags=0&meshinstall=6" "https://api.rmmtactical.com" 1 53 "b121c34d2737678e80b10613895f25e17de32493cbb0b19e412315700df6410218ef4" server
# EX: UPDATE 
#       ./rmmagent-linux.sh amd64 update
#!/bin/bash

if [ $EUID -ne 0 ]; then
  echo "ERROR: Must be run as root"
  exit 1
fi

if [[ $1 == "" ]]; then
        echo "First argument is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "help" ]]; then
        echo "There is help but more information is available at github.com/ZoLuSs/rmmagent-script"
        echo ""
        echo "List of argument (no argument name):"
        echo "Arg 1: 'install' or 'update'"
        echo "Arg 2: System type 'amd64' 'x86' 'arm64' 'armv6'"
        echo "Arg 3: Mesh agent URL"
        echo "Arg 4: API URL"
        echo "Arg 5: Client ID"
        echo "Arg 6: Site ID"
        echo "Arg 7: Auth Key"
        echo "Arg 8: Agent Type 'server' or 'workstation'"
        echo ""
        echo "Only argument 1 is needed for update"
        exit 0
fi

if [[ $1 != "install" && $1 != "update" ]]; then
        echo "First argument can only be 'install' or 'update' !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $2 == "" ]]; then
        echo "Argument 2 (System type) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $2 != "amd64" && $2 != "x86" && $2 != "arm64" && $2 != "armv6" ]]; then
        echo "This argument can only be 'amd64' 'x86' 'arm64' 'armv6' !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $3 == "" ]]; then
        echo "Argument 3 (Mesh agent URL) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $4 == "" ]]; then
        echo "Argument 4 (API URL) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $5 == "" ]]; then
        echo "Argument 5 (Client ID) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $6 == "" ]]; then
        echo "Argument 6 (Site ID) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $7 == "" ]]; then
        echo "Argument 7 (Auth Key) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $8 == "" ]]; then
        echo "Argument 8 (Agent Type) is empty !"
        echo "Type help for more information"
        exit 1
fi

if [[ $1 == "install" && $8 != "server" && $8 != "workstation" ]]; then
        echo "First argument can only be 'server' or 'workstation' !"
        echo "Type help for more information"
        exit 1
fi

if ! command -v unzip &> /dev/null
then
    echo "unzip cannot be found, it is needed.."    
    exit
fi

if ! command -v wget &> /dev/null
then
    echo "wget cannot be found, it is needed..."
    exit
fi

## Setting var for easy scription
system=$2
mesh_url=$3
rmm_url=$4
rmm_client_id=$5
rmm_site_id=$6
rmm_auth=$7
rmm_agent_type=$8

go_url_amd64="https://go.dev/dl/go1.20.linux-amd64.tar.gz"
go_url_x86="https://go.dev/dl/go1.20.linux-386.tar.gz"
go_url_arm64="https://go.dev/dl/go1.20.linux-arm64.tar.gz"
go_url_armv6="https://go.dev/dl/go1.20.linux-armv6l.tar.gz"

function go_install() {
        ## Installing golang
        case $system in
        amd64)
          wget -O /tmp/golang.tar.gz $go_url_amd64
                ;;
        x86)
          wget -O /tmp/golang.tar.gz $go_url_x86
        ;;
        arm64)
          wget -O /tmp/golang.tar.gz $go_url_arm64
        ;;
        armv6)
          wget -O /tmp/golang.tar.gz $go_url_armv6
        ;;
        esac
        
        tar -xvzf /tmp/golang.tar.gz -C /usr/local/
        rm /tmp/golang.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        export GOPATH=/usr/local/go
        export GOCACHE=/root/.cache/go-build

        echo "export PATH=/usr/local/go/bin" >> /root/.profile
        echo "Golang Install Done !"
}

function agent_compile() {
        ## Compiling and installing tactical agent from github
        echo "Agent Compile begin"
        wget -O /tmp/rmmagent.zip "https://github.com/amidaware/rmmagent/archive/refs/heads/master.zip"
        unzip /tmp/rmmagent -d /tmp/
        rm /tmp/rmmagent.zip
        cd /tmp/rmmagent-master
        case $system in
        amd64)
          env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o /tmp/temp_rmmagent
        ;;
        x86)
          env CGO_ENABLED=0 GOOS=linux GOARCH=386 go build -ldflags "-s -w" -o /tmp/temp_rmmagent
        ;;
        arm64)
          env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "-s -w" -o /tmp/temp_rmmagent
        ;;
        armv6)
          env CGO_ENABLED=0 GOOS=linux GOARCH=arm go build -ldflags "-s -w" -o /tmp/temp_rmmagent
        ;;
        esac
        
        cd /tmp
        rm -R /tmp/rmmagent-master
}

function update_agent() {
        systemctl stop tacticalagent

        cp /tmp/temp_rmmagent /usr/local/bin/rmmagent
        rm /tmp/temp_rmmagent

        systemctl start tacticalagent
}
function install_agent() {
        cp /tmp/temp_rmmagent /usr/local/bin/rmmagent
        /tmp/temp_rmmagent -m install -api $rmm_url -client-id $rmm_client_id -site-id $rmm_site_id -agent-type $rmm_agent_type -auth $rmm_auth
        rm /tmp/temp_rmmagent

        cat << "EOF" > /etc/systemd/system/tacticalagent.service
[Unit]
Description=Tactical RMM Linux Agent
[Service]
Type=simple
ExecStart=/usr/local/bin/rmmagent -m svc
User=root
Group=root
Restart=always
RestartSec=5s
LimitNOFILE=1000000
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now tacticalagent
  systemctl start tacticalagent
}

function install_mesh() {
  ## Installing mesh agent
  wget -O /tmp/meshagent $mesh_url
  chmod +x /tmp/meshagent
  mkdir /opt/tacticalmesh
  /tmp/meshagent -install --installPath="/opt/tacticalmesh"
  rm /tmp/meshagent
  rm /tmp/meshagent.msh
}

case $1 in
install)
        go_install
        install_mesh
        agent_compile
        install_agent
        echo "Tactical Agent Install is done"
        systemctl restart meshagent
        systemctl restart tacticalagent
        exit 0;;
update)
        go_install
        agent_compile
        update_agent
        echo "Tactical Agent Update is done"
        exit 0;;
esac
