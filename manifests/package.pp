
define fpm::package(
		$source_type = 'dir',
		$package_type = 'deb',
		$package_src,
		$package_version,
		$build_dirname = '/tmp/build',
		$install_dist = '/usr/local',
		$with_doc = true,
		$with_dev = true
) {

		$torque_packages_broker_dir = "/etc/puppet/modules/torque/files"

		if defined(File["${package_src}"]) {

			$gem_path = gem_path()

			file { "${name}_${build_dirname}":
				name => "${build_dirname}",
				ensure => directory,
			}

			exec { "${name}_make_install":
				path => "/bin:/usr/bin:/usr/sbin",
				cwd => "${package_src}",
				command => "make install DESTDIR=${build_dirname}",
				require => [
					File["${name}_${build_dirname}"],
					File["${package_src}"],
					Exec["build-torque"],
				],
			}

			exec { "${name}_build_package":
				cwd => "${package_src}",
				path => "${gem_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name} -v ${package_version} -C ${build_dirname} -p ${name}-VERSION_ARCH.${package_type} ${install_dist}/bin ${install_dist}/lib",
				require => Exec["${name}_make_install"],
			}

			exec { "${name}_build_doc":
				cwd => "${package_src}",
				path => "${gem_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name}-doc -v ${package_version} -C ${build_dirname} -p ${name}-doc-VERSION_ARCH.${package_type} usr/share/man",
				require => Exec["${name}_make_install"],
			}

			exec { "${name}_build_dev":
				cwd => "${package_src}",
				path => "${gem_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name}-dev -v ${package_version} -C ${build_dirname} -p ${name}-dev-VERSION_ARCH.${package_type} usr/include",
				require => Exec["${name}_make_install"],
			}

			exec { "${name}_store_build_package":
				cwd => "${package_src}",
				path => "/usr/bin:/bin",
				command => "mv *deb ${torque_packages_broker_dir}",
				require => [ Exec["${name}_build_package"], Exec["${name}_build_doc"], Exec["${name}_build_dev"] ], 
			}

		} else {
			alert("File['#{$package_src}'] is not defined")
		}

}

