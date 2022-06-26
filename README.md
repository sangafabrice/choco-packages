# **Avast Secure Browser**
[![Package Version](https://img.shields.io/badge/version-102.1.17190.115-brightgreen)](https://community.chocolatey.org/packages/avastsecure)

##### Author: Fabrice Sanga
<br/>


Avast **Secure** is a modern web browser that provides fast and encrypted secure browsing.

<br/>

## **Notes**

- This package uses Secure standalone installer and installs the 32-bit on 32-bit OSes and the 64-bit version on 64-bit OSes. If this package is installed on a 64-bit OS and the 32-bit version of Secure is already installed, the package keeps installing/updating the 32-bit version of Avast Secure.
- This package always installs the latest version of Avast Secure, regardless of the version specified in the package. Avast does not officially offer older versions of Secure for download. Because of this, it is required to use `choco (install|upgrade) avastsecure --force` switch to force the install of the latest version.
		
<br/>

![Package Build Version](https://img.shields.io/badge/build-3.0.1-blue)
