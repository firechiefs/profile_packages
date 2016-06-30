# PURPOSE:
# Installs packages in hiera via create_resources stlib function
#
# HIERA DATA:

# OSFAMILY PACKAGES
# profile::packages:
#   [windows|RedHat6|RedHat7]:

# VIRTUAL/PHYSICAL SPECIFIC PACKAGES
# profile::packages:
#   [$::virtual]:
#      windows:
#      RedHat6:
#      RedHat7:

# PACKAGE DEFAULTS:
# profile::packages:
#   defaults:
#     [RedHat6|RedHat7|windows]

# PACKAGE RESOURCES:
# Should be hash as documented here:
# https://docs.puppetlabs.com/references/latest/type.html#package

# REDHAT SPECIFIC:
# Make sure to check for duplicate packages
# yum list --showduplicates <pacakge>
# if duplicate pacakge exists, use 'present'

# HIERA EXAMPLE:
# profile::packages:
#   windows:
#     notepadplusplus.install:
#       ensure: '6.8.8'
#   RedHat6:
#     tree:
#       ensure: 'present'
#   RedHat7:
#     tree:
#       ensure: '1.2.3-el7'
#   vmware:
#      windows:
#        vmware-tools:
#          ensure: '10.0.0'
#   defaults:
#     windows:
#       provider: 'chocolatey'
#       source: '\\server\Install\windows\chocolatey'
#     RedHat:
#       provider: 'yum'
#
# MODULE DEPENDENCIES:
# puppet module install chocolatey-chocolatey

class profile_packages {
  # HIERA LOOKUP:
  # --> PUPPET CODE VARIABLES:
  # merge all Package data into one hash
  # hiera_hash merges keys from all yaml sources
  # http://docs.puppetlabs.com/puppet/latest/reference/function.html#hierahash
  $packages = hiera_hash('profile::packages')

  # HIERA LOOKUP VALIDATION:
  validate_hash($packages)

  # PUPPET CODE
  # grab $::osfamily defaults
  $osfamily_defaults = $packages[defaults][$::osfamily]

  case $::osfamily {
    'RedHat': {
      # concatenate osfamiy and operatingsystemmajrelease puppet facts
      # example: RedHat7
      $osfamily_majrel = "${::osfamily}${::operatingsystemmajrelease}"

      # determine osfamily_majrel packages
      $osfamily_packages = $packages[$osfamily_majrel]

      # if is_virtual = true, assign virtual packages
      # if is_virtual = false, assign physical hardware packages
      if ($::is_virtual) {
        # the virtual fact returns the hyper-visor name, e.g.:
        # vmware vms returns 'vmware'
        # virtualbox vms returns 'virtualbox'
        $hardware_packages  = $packages[$::virtual][$osfamily_majrel]
      }
      # else {
      #   # the manufacturer fact returns the hardware manufacturer, e.g.:
      #   # DELL systems return "Dell Inc."
      #   # Lenovo systems return "LENOVO", etc.
      #   unless $::manufacturer == 'Supermicro' {
      #     $hardware_packages  = $packages[$::manufacturer][$osfamily_majrel]
      #   }
      # }
    }
    'windows': {
      # package installs require chocolotey class
      require profile_chocolatey

      # windows doesn't require major release specific packages
      # that logic is handled by chocolatey
      # safe to base it on $::osfamily
      $osfamily_packages = $packages[$::osfamily]

      # if is_virtual = true, assign virtual packages
      # if is_virtual = false, assign physical packages
      if ($::is_virtual) {
        # the virtual fact returns the hyper-visor name, e.g.:
        # vmware vms returns 'vmware'
        # virtualbox vms returns 'virtualbox'
        $hardware_packages  = $packages[$::virtual][$::osfamily]
      }
      else {
        # the manufacturer fact returns the hardware manufacturer, e.g.:
        # DELL systems return "Dell Inc."
        # Lenovo systems return "LENOVO", etc.
        $hardware_packages  = $packages[$::manufacturer][$::osfamily]
      }
    }
    default: {
      fail("FAIL: PROFILE_PACKAGES not supported on ${::osfamily} !!!")
    }
  }

  # create packages
  create_resources(package, $osfamily_packages, $osfamily_defaults )
  if($hardware_packages) {
    create_resources(package, $hardware_packages, $osfamily_defaults)
  }

  ##################### VALIDATION CODE  ##########################
  validation_script { 'profile_packages':
    profile_name    => 'profile_packages',
    validation_data => merge($osfamily_packages, $hardware_packages),
  }

}
