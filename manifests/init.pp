
class fpm {
	package { fpm: ensure => present, provider => gem }
	include fpm::funcs
}
