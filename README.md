## PURPOSE:

Installs packages in hiera via create_resources stlib function

## HIERA DATA:
 OSFAMILY PACKAGES
 ```
 profile::packages:
   [windows|RedHat6|RedHat7]:
```
 VIRTUAL/PHYSICAL SPECIFIC PACKAGES
 ```
 profile::packages:
   [$::virtual]:
      windows:
      RedHat6:
      RedHat7:
```
 PACKAGE DEFAULTS:
```
profile::packages:
  defaults:
    [RedHat6|RedHat7|windows]
```
 PACKAGE RESOURCES:

 Should be hash as documented here:
 https://docs.puppetlabs.com/references/latest/type.html#package

 REDHAT SPECIFIC:

 Make sure to check for duplicate packages, if duplicate pacakge exists, use 'present'
 ```
 yum list --showduplicates <pacakge>
 ```

## HIERA EXAMPLE:
```
profile::packages:
  windows:
    notepadplusplus.install:
      ensure: '6.8.8'
  RedHat6:
    tree:
      ensure: 'present'
  RedHat7:
    tree:
      ensure: '1.2.3-el7'
    vmware:
      windows:
        vmware-tools:
          ensure: '10.0.0'
  defaults:
    windows:
      provider: 'chocolatey'
        source: '\\server\Install\windows\chocolatey'
    RedHat:
      provider: 'yum'
```

## MODULE DEPENDENCIES:
```
puppet module install chocolatey-chocolatey
```
## USAGE:

#### Puppetfile:
```
mod "chocolatey-chocolatey",  '1.2.1'

mod 'validation_script',
  :git => 'https://github.com/firechiefs/validation_script',
  :ref => '1.0.0'

mod 'profile_packages',
  :git => 'https://github.com/firechiefs/profile_packages',
  :ref => '1.0.0'
```
#### Manifests:
```
class role::*rolename* {
  include profile_packages
}
```
