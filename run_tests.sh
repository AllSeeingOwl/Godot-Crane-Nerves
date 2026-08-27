#!/bin/bash
xvfb-run --auto-servernum godot -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit -v
