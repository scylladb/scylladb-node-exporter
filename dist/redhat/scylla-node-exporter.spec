Name:           scylla-node-exporter
Version:        %{version}
Release:        %{release}
Summary:        Prometheus exporter for machine metrics
Group:          Applications/Databases
License:        ASL 2.0
URL:            https://github.com/prometheus/node_exporter

%undefine _missing_build_ids_terminate_build
%global _debugsource_template %{nil}
%global _debuginfo_subpackages %{nil}

%description
Prometheus exporter for machine metrics, written in Go with pluggable metric collectors.

%package -n scylla-enterprise-node-exporter
Summary:        Transitional package for scylla-node-exporter
Group:          Applications/Databases
Requires:       scylla-node-exporter = %{version}-%{release}

%description -n scylla-enterprise-node-exporter
This is a transitional package that installs scylla-node-exporter.
It can be safely removed.

%install
mkdir -p %{buildroot}/opt/scylladb/node_exporter/licenses
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_unitdir}
mkdir -p %{buildroot}/etc/systemd/system/scylla-node-exporter.service.d

install -m 0755 %{srcdir}/build/node_exporter.stripped %{buildroot}/opt/scylladb/node_exporter/node_exporter
install -m 0644 %{srcdir}/build/LICENSE %{buildroot}/opt/scylladb/node_exporter/licenses/LICENSE
install -m 0644 %{srcdir}/build/NOTICE %{buildroot}/opt/scylladb/node_exporter/licenses/NOTICE
install -m 0644 %{srcdir}/dist/sysconfig/scylla-node-exporter %{buildroot}%{_sysconfdir}/sysconfig/scylla-node-exporter
install -m 0644 %{srcdir}/dist/systemd/scylla-node-exporter.service %{buildroot}%{_unitdir}/scylla-node-exporter.service
install -m 0644 %{srcdir}/dist/systemd/scylla-node-exporter.service.d/dependencies.conf %{buildroot}/etc/systemd/system/scylla-node-exporter.service.d/dependencies.conf

%post
if [ $1 -eq 1 ] ; then
    /usr/bin/systemctl preset scylla-node-exporter.service ||:
fi

%preun
if [ $1 -eq 0 ] ; then
    /usr/bin/systemctl --no-reload disable scylla-node-exporter.service ||:
    /usr/bin/systemctl stop scylla-node-exporter.service ||:
fi

%postun
/usr/bin/systemctl daemon-reload ||:

%files
%defattr(-,root,root)
%config(noreplace) %{_sysconfdir}/sysconfig/scylla-node-exporter
%{_unitdir}/scylla-node-exporter.service
/opt/scylladb/node_exporter/node_exporter
/opt/scylladb/node_exporter/licenses/LICENSE
/opt/scylladb/node_exporter/licenses/NOTICE
/etc/systemd/system/scylla-node-exporter.service.d/dependencies.conf

%files -n scylla-enterprise-node-exporter
# empty - shadow package

%changelog
* Tue Apr 28 2026 Yaron Kaikov <yaronkaikov@scylladb.com>
- Extract standalone scylla-node-exporter RPM packaging (RELENG-497)
