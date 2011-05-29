
class fpm::funcs {

	define package(
		$source_type = 'dir',
		$package_type = 'deb',
		$package_src,
		$package_version,
		$build_dirname = '/tmp/build',
		$with_doc = true,
		$with_dev = true,
	) {

		$gem_path = gem_path()

		if defined(File["${package_src}"]) {
			file { "${name}_${build_dirname}": ensure => directory }
			exec { "${name}_make_install":
				path => "/bin:/usr/bin:/usr/sbin",
				command => "make install DESTDIR=${build_dirname}",
				require => [
					File["${name}_${build_dirname}"],
					File["${package_src}"],
				],
			}
			exec { "${name}_build_package":
				cwd => "${package_src}",
				path => "${gem_path}:/usr/bin:/bin",
				command => "fpm -s dir -t ${package_type} -n ${name} -v ${package_version} -C ${build_dirname} -p ${name}-VERSION_ARCH.${package_type} usr/bin usr/lib",
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
		} else {
			alert("File['#{$package_src}'] is not defined")
		}

	}

}


