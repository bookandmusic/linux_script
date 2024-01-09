#! /usr/bin/env bash

OS=Linux
ARCH=x86_64
COMMAND_PREX="sudo "

GITHUB_PROXY=https://ghproxy.com/

export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

NVM_INSTALL_VERSION="0.39.5"
NODE_VERSION="16.20.2"
NODE_PROXY="https://mirrors.ustc.edu.cn/node/"
NPM_PROXY="https://registry.npmmirror.com"

GO_VERSION="1.21.3"
GO_PROXY="http://mirrors.ustc.edu.cn/golang/"
GO_MOD_PROXY="https://goproxy.cn"

PYTHON_PROXY="https://registry.npmmirror.com/-/binary/python"
PYTHON_VERSION="3.12.0"
PYPI_PROXY="https://mirrors.ustc.edu.cn/pypi/web/simple"
DATE=$(date +%Y%m%d%H%M%S)
LOG_FILE=env_init_$DATE.log

function info() {
	echo -e "\e[1;32m$*\e[0m"
}

function waring() {
	echo -e "\e[1;33m$*\e[0m"
}

function error() {
	echo -e "\e[1;31m$*\e[0m"
	exit 1
}

function pre_check() {
	local os=$(uname)
	if [[ ${os} == "Darwin" ]]; then
		OS=Mac
	elif [[ ${os} == "Linux" ]]; then
		# 检查是否为CentOS
		if [ -f /etc/redhat-release ]; then
			OS=CentOS
		# 检查是否为Debian/Ubuntu
		elif [ -f /etc/debian_version ]; then
			OS=Debian
		else
			error "unknown os"
		fi
	else
		error "unknown os:${os}"
	fi
	info "The current OS: ${OS}"

	local arch=$(uname -m)
	if [[ $arch == "aarch64" ]]; then
		ARCH=arm64
	elif [[ $arch == "arm64" ]]; then
		ARCH=arm64
	elif [[ $arch == "x86_64" ]]; then
		ARCH=x86_64
	else
		error "unknown arch:${arch}"
	fi
	info "The current ARCH: ${ARCH}"

	local user=$(whoami)
	if [ "${user}" == "root" ]; then
		COMMAND_PREX=""
	else
		COMMAND_PREX="sudo"
	fi
	info "The current USER: ${user}"
}

function pre_start() {
	info "The start install required packages ..."
	# 1. 判断系统是Linux还是Mac
	if [[ ${OS} == "Mac" ]]; then
		echo "xcode-select --install"
		xcode-select --install &>/dev/null
	elif [[ ${OS} == "CentOS" ]]; then
		echo "${COMMAND_PREX} yum makecache && ${COMMAND_PREX} yum install -y git curl wget zsh vim"
		{
			${COMMAND_PREX} yum makecache && ${COMMAND_PREX} yum install -y git curl wget zsh vim
		} 
	elif [[ ${OS} == "Debian" ]]; then
		echo "${COMMAND_PREX} sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list && ${COMMAND_PREX} apt update && ${COMMAND_PREX} apt install -y sshpass ca-certificates git curl wget zsh vim"
		{
			${COMMAND_PREX} sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list &&
				${COMMAND_PREX} apt update &&
				${COMMAND_PREX} apt install -y sshpass ca-certificates git curl wget zsh vim
		} 

	fi
	info "The already install required packages"
}

function final_clear() {
	if [[ ${OS} == "Debian" ]]; then
		info "The clear ..."

		echo "${COMMAND_PREX} apt-get clean && ${COMMAND_PREX} rm -rf /var/lib/apt/lists/* && ${COMMAND_PREX} rm -rf /src/*.deb"
		{
			${COMMAND_PREX} apt-get clean &&
				${COMMAND_PREX} rm -rf /var/lib/apt/lists/* &&
				${COMMAND_PREX} rm -rf /src/*.deb
		} 

		info "The clear complete"
	fi
}

function config_localtime() {
	if [ ! -f "/etc/localtime" ]; then
		info "create /etc/localtime"
		echo "${COMMAND_PREX} ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
		${COMMAND_PREX} ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
	fi
}

function install_vimrc() {
	info "The start install vimrc ..."

	echo "git clone --depth=1 ${GITHUB_PROXY}https://github.com/amix/vimrc.git ~/.vim_runtime"
	git clone --depth=1 ${GITHUB_PROXY}https://github.com/amix/vimrc.git ~/.vim_runtime

	echo "sh ~/.vim_runtime/install_awesome_vimrc.sh"
	sh ~/.vim_runtime/install_awesome_vimrc.sh

	info "The already install vimrc"
}

function install_ohmyzsh() {
	info "The start install ohmyzsh ..."

	waring "execute ohmyzsh install.sh"
	echo "echo \"Y\" | /bin/bash -c \"\$(curl -fsSL ${GITHUB_PROXY}https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
	{
		export REMOTE=${GITHUB_PROXY}https://github.com/ohmyzsh/ohmyzsh.git &&
			echo "Y" | /bin/bash -c "$(curl -fsSL ${GITHUB_PROXY}https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	} 

	echo "git clone ${GITHUB_PROXY}https://github.com/zsh-users/zsh-autosuggestions.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
	{
		git clone ${GITHUB_PROXY}https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	} 

	echo "git clone ${GITHUB_PROXY}https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
	{
		git clone ${GITHUB_PROXY}https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	} 

	echo "sed -i 's@plugins=(git)@plugins=(sudo git zsh-autosuggestions zsh-syntax-highlighting)@g' ~/.zshrc"
	{
		sed -i 's@plugins=(git)@plugins=(sudo git zsh-autosuggestions zsh-syntax-highlighting)@g' ~/.zshrc
	} 

	info "The already install ohmyzsh"
}

function install_homebrew() {
	info "The start install homebrew ..."

	waring "execute homebrew install.sh"
	export HOMEBREW_INSTALL_FROM_API=1
	export HOMEBREW_API_DOMAIN=${HOMEBREW_API_DOMAIN}
	export HOMEBREW_BOTTLE_DOMAIN=${HOMEBREW_BOTTLE_DOMAIN}
	export HOMEBREW_BREW_GIT_REMOTE=${HOMEBREW_BREW_GIT_REMOTE}
	export HOMEBREW_CORE_GIT_REMOTE=${HOMEBREW_CORE_GIT_REMOTE}

	echo "/bin/bash -c \"$(curl -fsSL https://mirrors.ustc.edu.cn/misc/brew-install.sh)\""
	{
		/bin/bash -c "$(curl -fsSL https://mirrors.ustc.edu.cn/misc/brew-install.sh)"
	} 

	waring "config homebrew env"

	echo "" | tee -a ~/.bashrc ~/.zshrc
	echo "# homebrew" >>~/.zshrc
	if [[ ${OS} == "Mac" && ${ARCH} == "arm64" ]]; then
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' | tee -a ~/.bashrc ~/.zshrc
	elif [[ ${OS} != "Mac" ]]; then
		echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' | tee -a ~/.bashrc ~/.zshrc
	fi
	echo "export HOMEBREW_BREW_GIT_REMOTE=${HOMEBREW_BREW_GIT_REMOTE}" | tee -a ~/.bashrc ~/.zshrc
	echo "export HOMEBREW_CORE_GIT_REMOTE=${HOMEBREW_CORE_GIT_REMOTE}" | tee -a ~/.bashrc ~/.zshrc
	echo "export HOMEBREW_API_DOMAIN=${HOMEBREW_API_DOMAIN}" | tee -a ~/.bashrc ~/.zshrc
	echo "export HOMEBREW_BOTTLE_DOMAIN=${HOMEBREW_BOTTLE_DOMAIN}" | tee -a ~/.bashrc ~/.zshrc

	if [[ ${OS} == "Mac" && ${ARCH} == "arm64" ]]; then
		export PATH=$PATH:/opt/homebrew/bin/
	else
		export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin/
	fi

	info "The already install ohmyzsh"
}

function install_starship() {
	info "The start install starship ..."

	waring "execute starship install.sh"

	echo "mkdir -p \$HOME/.local/bin && mkdir -p \$HOME/.config"
	mkdir -p $HOME/.local/bin && mkdir -p $HOME/.config

	export BASE_URL="${GITHUB_PROXY}https://github.com/starship/starship/releases"
	export BIN_DIR="$HOME/.local/bin"

	echo "curl -sSL ${GITHUB_PROXY}https://raw.githubusercontent.com/starship/starship/master/install/install.sh > starship_install.sh &&
			sed -i 's@confirm "Install Starship@# confirm "Install Starship@g' starship_install.sh &&
			sh starship_install.sh &&
			rm -rf starship_install.sh"
	{
		curl -sSL ${GITHUB_PROXY}https://raw.githubusercontent.com/starship/starship/master/install/install.sh >starship_install.sh &&
			sed -i 's@confirm "Install Starship@# confirm "Install Starship@g' starship_install.sh &&
			sh starship_install.sh &&
			rm -rf starship_install.sh
	} 

	waring "generate starship.toml"
	echo "export PATH=$PATH:~/.local/bin && starship preset tokyo-night -o ~/.config/starship.toml"
	export PATH=$PATH:~/.local/bin && starship preset tokyo-night -o ~/.config/starship.toml

	waring "config starship env"
	echo "" | tee -a ~/.bashrc ~/.zshrc
	echo '# starship' | tee -a ~/.bashrc ~/.zshrc
	echo 'export PATH=$PATH:~/.local/bin' | tee -a ~/.bashrc ~/.zshrc
	echo 'eval "$(starship init zsh)"' >>~/.zshrc && echo 'eval "$(starship init bash)"' >>~/.bashrc

	info "The already install starship"
}

function install_gvm() {
	info "The start install gvm ..."

	if [[ ${OS} == "Mac" ]]; then
		echo "brew update && brew install mercurial"
		{
			brew update && brew install mercurial
		} 
	elif [[ ${OS} == "CentOS" ]]; then
		echo "${COMMAND_PREX} yum install -y gcc bison make glibc-devel"
		{
			${COMMAND_PREX} yum install -y gcc bison make glibc-devel
		} 
	elif [[ ${OS} == "Debian" ]]; then
		echo "${COMMAND_PREX} apt update && ${COMMAND_PREX} apt install -y mercurial make binutils bison gcc build-essential bsdmainutils"
		{
			${COMMAND_PREX} apt update && ${COMMAND_PREX} apt install -y mercurial make binutils bison gcc build-essential bsdmainutils
		} 
	fi

	waring "execute gvm-installer"
	echo "export SRC_REPO=${GITHUB_PROXY}https://github.com/moovweb/gvm.git &&
			bash < <(curl -sSL ${GITHUB_PROXY}https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)"
	{
		export SRC_REPO=${GITHUB_PROXY}https://github.com/moovweb/gvm.git &&
			bash < <(curl -sSL ${GITHUB_PROXY}https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
	} 

	waring "config gvm env"
	echo "" | tee -a ~/.bashrc ~/.zshrc
	echo '# gvm' | tee -a ~/.bashrc ~/.zshrc
	echo "export GO_BINARY_BASE_URL=${GO_PROXY}" | tee -a ~/.bashrc ~/.zshrc
	echo '[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"' | tee -a ~/.bashrc ~/.zshrc
	echo 'export GOROOT_BOOTSTRAP=$GOROOT' | tee -a ~/.bashrc ~/.zshrc
	echo "export GOPROXY=${GO_MOD_PROXY},direct" | tee -a ~/.bashrc ~/.zshrc

	export GO_BINARY_BASE_URL=${GO_PROXY}
	export GOROOT_BOOTSTRAP=$GOROOT
	export GOPROXY=${GO_MOD_PROXY},direct
	[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

	info "The already install gvm"

	waring "clone go src repo to $HOME/.gvm/archive/go"
	echo "git ${GITHUB_PROXY}https://github.com/golang/go.git \$HOME/.gvm/archive/go"
	git clone ${GITHUB_PROXY}https://github.com/golang/go.git $HOME/.gvm/archive/go

	waring "install go${GO_VERSION}"
	{
		gvm install go${GO_VERSION} -B && gvm use go${GO_VERSION} --default
	} 
}

function install_pyenv() {
	info "The start install pyenv ..."

	if [[ ${OS} == "Mac" ]]; then
		echo "brew install openssl readline sqlite3 xz zlib tcl-tk"
		{
			brew install openssl readline sqlite3 xz zlib tcl-tk
		} 
	elif [[ ${OS} == "CentOS" ]]; then
		echo "${COMMAND_PREX} yum install -y gcc make patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel"
		{
			${COMMAND_PREX} yum install -y gcc make patch zlib-devel bzip2 bzip2-devel \
				readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
		} 
	elif [[ ${OS} == "Debian" ]]; then
		echo "${COMMAND_PREX} apt update && ${COMMAND_PREX} apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
		{
			${COMMAND_PREX} apt update && ${COMMAND_PREX} apt install -y build-essential libssl-dev zlib1g-dev \
				libbz2-dev libreadline-dev libsqlite3-dev curl \
				libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
		} 
	fi

	echo "git clone ${GITHUB_PROXY}https://github.com/yyuu/pyenv.git ~/.pyenv"
	{
		git clone ${GITHUB_PROXY}https://github.com/yyuu/pyenv.git ~/.pyenv
	} 

	echo "mkdir -p ~/.pyenv/plugins && git clone ${GITHUB_PROXY}https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv"
	{
		mkdir -p ~/.pyenv/plugins && git clone ${GITHUB_PROXY}https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
	} 

	waring "config pyenv env"
	echo "" | tee -a ~/.bashrc ~/.zshrc
	echo "# pyenv" | tee -a ~/.bashrc ~/.zsrc
	echo 'export PYENV_ROOT="$HOME/.pyenv"' | tee -a ~/.bashrc ~/.zshrc
	echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' | tee -a ~/.bashrc ~/.zshrc
	echo 'eval "$(pyenv init -)"' | tee -a ~/.bashrc ~/.zshrc
	echo 'eval "$(pyenv virtualenv-init -)"' | tee -a ~/.bashrc ~/.zshrc
	echo 'export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1' | tee -a ~/.bashrc ~/.zshrc
	echo "export PYTHON_BUILD_MIRROR_URL=${PYTHON_PROXY}" | tee -a ~/.bashrc ~/.zshrc

	export PYENV_ROOT="$HOME/.pyenv"
	export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
	export PYTHON_BUILD_MIRROR_URL=${PYTHON_PROXY}
	command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"

	info "The already install pyenv"

	info "install python ${PYTHON_VERSION}"
	{
		pyenv install ${PYTHON_VERSION} &&
			pyenv global ${PYTHON_VERSION} &&
			pip install -i ${PYPI_PROXY} pip -U &&
			pip config set global.index-url ${PYPI_PROXY}
	} 
}

function install_nvm() {
	info "The start install nvm ..."

	echo "git clone ${GITHUB_PROXY}https://github.com/nvm-sh/nvm.git ~/.nvm && git -C ~/.nvm checkout v${NVM_INSTALL_VERSION}"
	{
		git clone ${GITHUB_PROXY}https://github.com/nvm-sh/nvm.git ~/.nvm && git -C ~/.nvm checkout v${NVM_INSTALL_VERSION}
	} 

	waring "config nvm env"
	echo "" | tee -a ~/.bashrc ~/.zshrc
	echo "# nvm" | tee -a ~/.bashrc ~/.zshrc
	echo 'export NVM_DIR="$HOME/.nvm"' | tee -a ~/.bashrc ~/.zshrc
	echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' | tee -a ~/.bashrc ~/.zshrc
	echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' | tee -a ~/.bashrc ~/.zshrc
	echo '# node' | tee -a ~/.bashrc ~/.zshrc
	echo "export NVM_NODEJS_ORG_MIRROR=${NODE_PROXY}" | tee -a ~/.bashrc ~/.zshrc

	export NVM_DIR="$HOME/.nvm"
	export NVM_NODEJS_ORG_MIRROR=${NODE_PROXY}
	[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"                   # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion" # This loads nvm bash_completion

	info "The already install nvm"

	info "install node ${NODE_VERSION}"
	{
		nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION}
	} 

	{
		export PATH=$PATH:$HOME/.nvm/versions/node/v${NODE_VERSION}/bin &&
			npm install --registry ${NPM_PROXY} -g yarn &&
			npm config set registry ${NPM_PROXY} &&
			yarn config set registry ${NPM_PROXY}
	} 
}

function main() {
	exec > >(tee -a $LOG_FILE) 2>&1
	pre_check
	pre_start
	config_localtime
	install_vimrc
	install_ohmyzsh
	install_homebrew
	install_starship
	install_gvm
	install_nvm
	install_pyenv
	final_clear
}

main
