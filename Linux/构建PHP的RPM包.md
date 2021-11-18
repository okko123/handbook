构建RPM包
https://blog.linuxeye.cn/431.html
http://blog.51cto.com/foolishfish/1432087
https://linuxeye.com/431.html

spec内建变量
https://rpm.org/user_doc/macros.html

src.rpm的下载地址
http://vault.centos.org/7.6.1810/os/Source/SPackages/
https://dl.iuscommunity.org/pub/ius/stable/Redhat/7/SRPMS/repoview/php72u.html

rpmbuild --showrc显示所有的宏，以下划线开头，一个下划线：定义环境的使用情况，二个下划线：通常定义的是命令，为什么要定义宏，因为不同的系统，命令的存放位置可能不同，所以通过宏的定义找到命令的真正存放位置

rpmbuild命令
rpmbuild -bp — Execute %prep
rpmbuild -bc — Execute %prep, %build
rpmbuild -bi — Execute %prep, %build, %install, %check
rpmbuild -bb — Execute %prep, %build, %install, %check, package (bin)
rpmbuild -ba — Execute %prep, %build, %install, %check, package (bin, src)
rpmbuild -bl — Check %files list


问题
RPM build errors:
    Installed (but unpackaged) file(s) found:
http://www.huilog.com/?p=720
http://jackxiang.com/post/8633/
http://www.voidcn.com/article/p-kleosilr-bez.html

spec 主体
%prep 预处理脚本
%setup 通常是从/usr/src/redhat/SOURCES里的包解压到/usr/src/redhat/BUILD/%{name}-%{version}中。
一般用%setup -c就可以了，但有两种情况：一就是同时编译多个源码包，二就是源码的tar包的名称与解压出来的目录不一致，此时，就需要使用-n参数指定一下了。
%build 开始构建包,在/usr/src/redhat/BUILD目录中
%install 开始把软件安装到虚拟的根目录中,这个很重要，因为如果这里的路径不对的话，则下面%files中寻找文件的时候就会失败。
可以使用：make DESTDIR=$RPM_BUILD_ROOT install
或者使用常规的系统命令 cp -rf filename $RPM_BUILD_ROOT/
%clean 清理临时文件,注意区分$RPM_BUILD_ROOT和$RPM_BUILD_DIR：
$RPM_BUILD_ROOT是指开头定义的BuildRoot，而$RPM_BUILD_DIR通常就是指/usr/src/redhat/BUILD，其中，前面的才是%files需要的。
%pre rpm安装前执行的脚本
%post rpm安装后执行的脚本
%preun rpm卸载前执行的脚本
%postun rpm卸载后执行的脚本
%preun %postun 的区别是前者在升级rpm包的时候会执行，后者在升级rpm包的时候不会执行
%files 定义那些文件或目录会放入rpm中,下面的路径不是系统的绝对路径而是$RPM_BUILD_ROOT下的路径
%defattr 指定安装rpm包后的文件属性，分别是(mode,owner,group)，-表示默认值，对文本文件是0644，可执行文件是0755
%package
%description 软件的详细说明
%configure

spec关键字
Summary: rpm的内容概要
Name: rpm的名称，后面可使用%{name}的方式引用
Version: rpm的实际版本号，例如：1.2.5等，后面可使用%{version}引用
Release: 发布序列号，例如:1等，标明第几次打包，后面可使用%{release}引用
License: 软件授权方式，通常就是GPL
Group: 软件分组
Source: 源代码包，可以带多个用Source1、Source2等源，后面也可以用%{source1}、%{source2}引用
Build Arch: 指编译的目标处理器架构，noarch标识不指定，但通常都是以/usr/lib/rpm/marcros中的内容为默认值
BuildRoot: 这个是安装或编译时使用的“虚拟目录”，考虑到多用户的环境，一般定义为：
%{_tmppath}/%{name}-%{version}-%{release}-root
或%{_tmppath}/%{name}-%{version}-%{release}-buildroot-%(%{__id_u} -n}
该参数非常重要，因为在生成rpm的过程中，执行make install时就会把软件安装到上述的路径中，在打包的时候，同样依赖“虚拟目录”为“根目录”进行操作。
后面可使用$RPM_BUILD_ROOT 方式引用。
URL: 软件的主页
Packager: 打包者的信息
Requires: 该rpm包所依赖的软件包名称，可以用>=或<=表示大于或小于某一特定版本，例如：
libpng-devel >= 1.0.20
“>=”号两边需用空格隔开，而不同软件名称也用空格分开
%description 软件的详细说明
