
define fpm::torque(
		$source_type = 'dir',
		$package_type = 'deb',
		$package_src,
		$package_version,
		$build_dirname = '/tmp/build',
		$install_dist = '/usr/local',
		$broker_dir = "/tmp",
		$repo,
		$with_doc = true,
		$with_dev = true
) {

		include torque::install
		include torque::params

		$package_dir = regsubst( $install_dist, '^/', '' )
		$doc_dir = regsubst( "${install_dist}/man", '^/', '' )
		$dev_dir = regsubst( "${install_dist}/include", '^/', '' )
		$spool_dir = regsubst( "${$torque::params::spool_dir}", '^/', '' )
		$initd_dir = "${build_dirname}/etc/init.d"

		if defined(File["${package_src}"]) {

			file { "${name}_${build_dirname}":
				name => "${build_dirname}",
				ensure => directory,
			}

			exec { "${name}_make_install":
				path => "/bin:/usr/bin:/usr/sbin",
				cwd => "${package_src}",
				command => "nice -19 make install DESTDIR=${build_dirname}",
				require => [
					File["${name}_${build_dirname}"],
					File["${package_src}"],
					Exec["build-torque"],
				],
				timeout => 600,
				unless => "test -e ${build_dirname}/${package_dir}",
			}

			exec { "${name}_build_package":
				cwd => "${package_src}",
				path => "${gem_bin_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name} -v ${package_version} -C ${build_dirname} -p ${name}-VERSION_ARCH.${package_type} ${package_dir}/bin ${package_dir}/lib ${package_dir}/sbin ${spool_dir}",
				require => [ Package['fpm'], Exec["${name}_make_install"], ],
				timeout => 600,
				unless => "ls ${broker_dir}/${name}-*deb"
			}

			exec { "${name}_build_doc":
				cwd => "${package_src}",
				path => "${gem_bin_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name}-doc -v ${package_version} -C ${build_dirname} -p ${name}_doc-VERSION_ARCH.${package_type} ${doc_dir}",
				require => [ Package['fpm'], Exec["${name}_make_install"], ],
				timeout => 600,
				unless => "ls ${broker_dir}/${name}_doc*deb"
			}

			exec { "${name}_build_dev":
				cwd => "${package_src}",
				path => "${gem_bin_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name}-dev -v ${package_version} -C ${build_dirname} -p ${name}_dev-VERSION_ARCH.${package_type} ${dev_dir}",
				require => [ Package['fpm'], Exec["${name}_make_install"], ],
				timeout => 600,
				unless => "ls ${broker_dir}/${name}_dev*deb"
			}

			file { "${build_dirname}/etc":
				ensure => directory,
				require => Exec["${name}_make_install"],
			}

			file { "${build_dirname}/etc/init.d":
				ensure => directory,
				require => file["${build_dirname}/etc"],
				before => Exec["${name}_cp_initd"],
			}

			exec { "${name}_cp_initd":
				path => "/usr/bin:/bin",
				command => "cp /etc/init.d/pbs* ${build_dirname}/etc/init.d",
				timeout => 600,
				require => [
					Replace['ensure_torque_server_path'],
					Replace['ensure_torque_sched_path'],
					Replace['ensure_torque_mom_path'],
				],
			}

			exec { "${name}_build_initd":
				cwd => "${package_src}",
				path => "${gem_bin_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name}-initd -v ${package_version} -C ${build_dirname} -p ${name}_initd-VERSION_ARCH.${package_type} etc/init.d",
				timeout => 600,
				unless => "ls ${broker_dir}/${name}_initd*deb",
				require => [ Package['fpm'], Exec["${name}_cp_initd"], ],
			}

			exec { "${name}_store_build_package":
				cwd => "${package_src}",
				path => "/usr/bin:/bin",
				command => "mv *deb ${broker_dir}",
				require => [
					Exec["${name}_build_package"],
					Exec["${name}_build_doc"],
					Exec["${name}_build_dev"],
					Exec["${name}_build_initd"],
				],
				timeout => 600,
				onlyif => "ls ${package_src}/*deb",
			}

			# $debs = mongo_putfiles($repo)
			# notify{"$hostname execute ${repo} => ${debs}":}

		} else {
			alert("File['#{$package_src}'] is not defined")
		}

}

