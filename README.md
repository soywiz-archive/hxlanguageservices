Haxe Language Services
======================

[![Build Status](https://travis-ci.org/soywiz/hxlanguageservices.svg?branch=master)](https://travis-ci.org/soywiz/hxlanguageservices)

The aim for this project is to provide haxe language services completely written in haxe that are able to
work anywhere without a server or even an haxe compiler providing completion, refactoring, references services
and providing unified code to debug the haxe compiled code for several languages like flash, cpp or javascript.

These services will allow to create a proper IDE with proper tooling (completion, renaming, organizing imports, debugging, unittests...) easily.

This project is initially based on [hscript](https://github.com/HaxeFoundation/hscript) work
and modified to get type information and to provide other language services.
