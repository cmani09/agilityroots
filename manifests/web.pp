class web_package{
include web
include mysql
include tomcat
}
class web{
case $operatingsystem {
    'CentOS', 'RedHat': {
      if $architecture == "x86_64" {
        package { 'httpd':
          name   => "httpd.x86_64",
          ensure => installed,
        }
      } else {
        package { 'httpd':
          name   => "httpd.i386",
          ensure => installed,
        }
      }
	 service { 'httpd':
 	 ensure => running,
	}

      file { "http.conf":
        path   => "/etc/httpd/conf/httpd.conf",
        owner  => root,
        group  => root,
        mode   => 0644,
        #source => $apacheconf ? {
         # 'default' => "puppet:///modules/apache/httpd.conf",
      #}
}
	}
    }
}
class mysql{
# install mysql-server package
package { 'mysql-community-server':
  ensure => installed,
}
service { 'mysqld':
  ensure => running,
  require => Package["mysql-community-server"]
}

}

class tomcat{
exec {'download_tomcat':
command => '/usr/bin/wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.62/bin/apache-tomcat-7.0.62.tar.gz -O /opt/apache-tomcat-7.0.62.tar.gz',
creates => '/opt/apache-tomcat-7.0.62.tar.gz'
}
exec {'extract_tomcat':
  unless => '/usr/bin/test -d /opt/apache-tomcat-7.0.62',
  cwd => '/opt/',
  command => '/usr/bin/tar -zxvf apache-tomcat-7.0.62.tar.gz',
}

file { '/opt/tomcat':
    ensure  => 'link',
    target  => '/opt/apache-tomcat-7.0.62',
    require => Exec['extract_tomcat'],
  }

file { '/opt/apache-tomcat-7.0.62/conf/tomcat-users.xml':
     owner   => 'tomcat',
     group   => 'tomcat',
     notify => Exec['tomcat_restart'],
     source  => 'puppet:///modules/web/tomcat-users.xml',
}

file { '/etc/init.d/tomcat':
    source => 'puppet:///modules/web/tomcat',
    ensure => 'present',
    mode => '755',
  }
group { 'tomcat': }
 user { 'tomcat':
    uid              => '91',
    comment          => 'tomcat user',
    ensure           => 'present',
    expiry           => absent,
    forcelocal       => true,
    gid              => 'tomcat',
    home             => '/usr/share/tomcat',
    password_max_age => '-1',
    system           => true,
    require          => Group['tomcat'],
  }

 file { [ '/opt/tomcat/logs',
           '/opt/tomcat/bin',
           '/opt/tomcat/conf',
           '/opt/tomcat/lib',
           '/opt/tomcat/temp',
           '/opt/tomcat/work',
           '/opt/tomcat/webapps' ]:
    owner   => 'tomcat',
    group   => 'tomcat',
    recurse => true,
    notify => Exec['tomcat_restart'],
  } 

  exec { 'tomcat_restart':
   command => '/etc/init.d/tomcat restart' 
  }
}
