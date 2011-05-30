
class fpm {
	package { fpm: ensure => present, provider => gem }
}
