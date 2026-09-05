#!/bin/bash
xvfb-run --auto-servernum godot --rendering-driver opengl3 -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -v
