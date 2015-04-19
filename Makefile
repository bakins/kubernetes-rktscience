APPC_VERSION		= 0.5.1
ETCD_VERSION		= 2.0.9
FLANNEL_VERSION		= 0.3.1
KUBERNETES_VERSION	= 0.15.0
OS					= linux
ARCH				= amd64
KUBE_RELEASE		= $(KUBERNETES_VERSION)-$(OS)-$(ARCH)
FLANNEL_RELEASE		= $(FLANNEL_VERSION)-$(OS)-$(ARCH)
ETCD_RELEASE		= $(ETCD_VERSION)-$(OS)-$(ARCH)

GO      = go
GFLAGS  = -a -tags netgo
ACTOOL	= workspace/bin/actool



.PHONY: all clean clean-bin clean-aci

all: etcd kubernetes flannel

clean: clean-bin clean-aci
	@rm -rf workspace

clean-bin:
	@rm -rf workspace/bin

clean-aci:
	@rm -rf workspace/aci-build
	@rm -rf workspace/aci/*.aci

workspace/aci:
	@mkdir -p $@

workspace/bin:
	@mkdir -p workspace/bin

.PRECIOUS: workspace/aci-build/%/rootfs/bin
workspace/aci-build/%/rootfs/bin:
	@echo " FILE $@"
	@mkdir -p $@
	@cp -r aci/$* workspace/aci-build
	@cp $^ $@


etcd: \
	workspace/aci/etcd-$(ETCD_RELEASE).aci

workspace/aci/etcd-$(ETCD_RELEASE).aci: actool workspace/aci-build/etcd/rootfs/bin | workspace/aci
	@echo " ACI  $@"
	@$(ACTOOL) build --overwrite workspace/aci-build/etcd $@

workspace/aci-build/etcd/rootfs/bin: workspace/bin/etcd

workspace/bin/etcd: workspace/gopath/src/github.com/coreos/etcd
	@echo " GO   $@"
	@$(eval export CGO_ENABLED=0)
	@$(eval export GOOS=linux)
	@$(eval export GOARCH=amd64)
	@$(eval export GOPATH=$(CURDIR)/workspace/gopath:$(CURDIR)/workspace/gopath/src/github.com/coreos/etcd/Godeps/_workspace)
	@$(GO) build $(GFLAGS) -o workspace/bin/etcd github.com/coreos/etcd

.PRECIOUS: workspace/gopath/src/github.com/coreos/etcd
workspace/gopath/src/github.com/coreos/etcd:
	@echo " GIT  $@"
	@mkdir -p $@
	@git clone --quiet --depth=1 --single-branch --no-checkout --branch v$(ETCD_VERSION) https://github.com/coreos/etcd.git $@
	@cd $@ ; git checkout --quiet v$(ETCD_VERSION)


kubernetes: \
	workspace/aci/kubelet-$(KUBE_RELEASE).aci \
	workspace/aci/kube-proxy-$(KUBE_RELEASE).aci \
	workspace/aci/kube-scheduler-$(KUBE_RELEASE).aci \
	workspace/aci/kube-apiserver-$(KUBE_RELEASE).aci \
	workspace/aci/kube-controller-manager-$(KUBE_RELEASE).aci

workspace/aci/%-$(KUBE_RELEASE).aci: actool workspace/aci-build/%/rootfs/bin | workspace/aci
	@echo " ACI  $@"
	@$(ACTOOL) build --overwrite workspace/aci-build/$* $@

.PRECIOUS: \
	workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes \ 
	workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes/cmd/kubelet \
	workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kube-apiserver \
	workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kube-controller-manager \
	workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kube-proxy \
	workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/plugin/cmd/kube-scheduler

workspace/aci-build/kubelet/rootfs/bin: workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kubelet
workspace/aci-build/kube-apiserver/rootfs/bin: workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kube-apiserver
workspace/aci-build/kube-controller-manager/rootfs/bin: workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kube-controller-manager
workspace/aci-build/kube-proxy/rootfs/bin: workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/cmd/kube-proxy
workspace/aci-build/kube-scheduler/rootfs/bin: workspace/bin/linux_amd64/GoogleCloudPlatform/kubernetes/plugin/cmd/kube-scheduler

workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes%: workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes
workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes:
	@echo " GIT  $@"
	@mkdir -p $@
	@git clone --quiet --depth=1 --single-branch --no-checkout --branch v$(KUBERNETES_VERSION) https://github.com/GoogleCloudPlatform/kubernetes.git $@
	@cd $@ ; git checkout --quiet v$(KUBERNETES_VERSION)

workspace/bin/linux_amd64: workspace/bin
	@mkdir -p workspace/bin/linux_amd64

workspace/bin/linux_amd64/%: workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes
	@echo " GO   $@"
	@$(eval export CGO_ENABLED=0)
	@$(eval export GOOS=linux)
	@$(eval export GOARCH=amd64)
	@$(eval export GOPATH=$(CURDIR)/workspace/gopath:$(CURDIR)/workspace/gopath/src/github.com/GoogleCloudPlatform/kubernetes/Godeps/_workspace)
	@$(GO) build $(GFLAGS) -o $@ github.com/$*


flannel: \
	workspace/aci/flannel-$(FLANNEL_RELEASE).aci

workspace/aci/flannel-$(FLANNEL_RELEASE).aci: actool workspace/aci-build/flannel/rootfs/bin | workspace/aci
	@echo " ACI  $@"
	@$(ACTOOL) build --overwrite workspace/aci-build/flannel $@

workspace/aci-build/flannel/rootfs/bin: workspace/bin/flanneld

workspace/bin/flanneld: workspace/gopath/src/github.com/coreos/flannel
	@echo " GO   $@"
	@$(eval export CGO_ENABLED=1)
	@$(eval export GOOS=linux)
	@$(eval export GOARCH=amd64)
	@$(eval export GOPATH=$(CURDIR)/workspace/gopath:$(CURDIR)/workspace/gopath/src/github.com/coreos/flannel/Godeps/_workspace)
	@$(GO) build $(GFLAGS) --ldflags '-extldflags "-static"' -o workspace/bin/flanneld github.com/coreos/flannel

.PRECIOUS: workspace/gopath/src/github.com/coreos/flannel
workspace/gopath/src/github.com/coreos/flannel:
	@echo " GIT  $@"
	@mkdir -p $@
	@git clone --quiet --depth=1 --single-branch --no-checkout --branch v$(FLANNEL_VERSION) https://github.com/coreos/flannel.git $@
	@cd $@ ; git checkout --quiet v$(FLANNEL_VERSION)



actool: \
	workspace/bin/actool

.PRECIOUS: workspace/bin/actool
workspace/bin/actool: workspace/gopath/src/github.com/appc/spec/actool
	@echo " GO   $@"
	@$(eval export GOOS=)
	@$(eval export GOARCH=)
	@$(eval export GOPATH=$(CURDIR)/workspace/gopath:$(CURDIR)/workspace/gopath/src/github.com/appc/spec/Godeps/_workspace)
	@$(GO) build $(GFLAGS) -o workspace/bin/actool github.com/appc/spec/actool

.PRECIOUS: workspace/gopath/src/github.com/appc/spec/actool
workspace/gopath/src/github.com/appc/spec/actool: workspace/gopath/src/github.com/appc/spec

workspace/gopath/src/github.com/appc/spec:
	@echo " GIT  $@"
	@mkdir -p $@
	@git clone --quiet --depth=1 --single-branch --no-checkout --branch v$(APPC_VERSION) https://github.com/appc/spec.git $@
	@cd $@ ; git checkout --quiet v$(APPC_VERSION)
