#!/bin/bash

print_with_color ()
{
	case $1 in
		"black")
			COLORSTR="\033[30m"
			;;
		"red")
			COLORSTR="\033[31m"
			;;
		"green")
			COLORSTR="\033[32m"
			;;
		"yellow")
			COLORSTR="\033[33m"
			;;
		"blue")
			COLORSTR="\033[34m"
			;;
		"magenta")
			COLORSTR="\033[35m"
			;;
		"cyan")
			COLORSTR="\033[36m"
			;;
		"white")
			COLORSTR="\033[37m"
			;;
		*)
			COLORSTR="\033[39m"
			;;
	esac
	echo -en "$COLORSTR"
	echo -en "$2"
	echo -e "\033[39m"
}

src_test ()
{
	if [ "$SRC_MUST_EXIST" != "1" ];
	then
		printf "%-32s" "'src' test... "
	fi
	if test -d src;
	then
		print_with_color "green" "OK!"
	else
		if [ "$SRC_MUST_EXIST" = "1" ];
		then
			print_with_color "red" "Something went bad!"
			exit -1;
		else
			echo -n "FAIL, creating... "
			mkdir src
			SRC_MUST_EXIST=1
			src_test
		fi
	fi
}

obj_test ()
{
	if [ "$OBJ_MUST_EXIST" != "1" ];
	then
		printf "%-32s" "'obj' test... "
	fi
	if test -d obj;
	then
		print_with_color "green" "OK!"
	else
		if [ "$OBJ_MUST_EXIST" = "1" ];
		then
			print_with_color "red" "Something went bad!"
			exit -1;
		else
			echo -n "FAIL, creating... "
			mkdir obj
			touch obj/.gitkeep
			OBJ_MUST_EXIST=1
			obj_test
		fi
	fi
}

src_code_test ()
{
	array=(src/*.c*)
	if [ "${array[0]}" = "src/*.c*" ];
	then
		print_with_color "red" "No source detected in 'src', create some!"
		EXIT_AFTER_TESTS=1
	else
		printf "%-32s" "'source code' test... "
		print_with_color "green" "OK!"
	fi
}

detect_language ()
{
	array=(src/*.c*)
	for ((i=0;i<${#array[@]};i+=1));
	do
		filename=$(basename ${array[$i]})
		case "${filename##*.}" in
			"c")
				LANGUAGE="C"
				;;
			*)
				# if it's got a weird file extension, it's c++, right?
				LANGUAGE="C++"
				;;
		esac
		FILE_EXTENSION="${filename##*.}"
	done
}

detect_header_files ()
{
	array=(src/*.h*)
	if [ "${array[0]}" = "src/*.h*" ];
	then
		print_with_color "yellow" "No headers detected in 'src'."
	else
		HEADERS="${array[0]}"
		for ((i=1;i<${#array[@]};i+=1));
		do
			HEADERS="$HEADERS ${array[$i]}"
		done
	fi
}

detect_objects ()
{
	sourcearray=(src/*.c*)
	for ((i=0;i<${#sourcearray[@]};i+=1));
	do
		filename="$(basename ${sourcearray[$i]})"
		if [ $i -eq 0 ];
		then
			OBJECTS="obj/${filename%.*}.o"
		else
			OBJECTS="$OBJECTS obj/${filename%.*}.o"
		fi
	done
}

detect_libraries ()
{
	arg=("$@")

	for ((i=0;i<${#arg[@]};i+=1));
	do
		case "${arg[$i]}" in
			"-f" | "--flags")
				FLAGS="${arg[$i+1]}"
				;;
			"-lf" | "--linkflags")
				LINKFLAGS="${arg[$i+1]}"
				;;
			"-cf" | "--compileflags")
				COMPILEFLAGS="${arg[$i+1]}"
				;;
			*)
				;;
		esac
	done

	# prepend to the thing, $FLAGS is global flags
	LINKFLAGS="$FLAGS $LINKFLAGS"
	COMPILEFLAGS="$FLAGS $COMPILEFLAGS"

	print_with_color "magenta" "LINKFLAGS=\$(FLAGS) $LINKFLAGS"
	print_with_color "magenta" "COMPILEFLAGS=\$(FLAGS) $COMPILEFLAGS"
}

generate_makefile ()
{
	PROJECT_NAME=$(basename `pwd`)
	echo \
"# Makefile, autogenerated by mfjen
# Edit at will, regenerating obliterates changes, fair warning

COMPILER=$COMPILER

COMPILEFLAGS=\$(FLAGS) $COMPILEFLAGS
LINKFLAGS=\$(FLAGS) $LINKFLAGS

HEADERS=$HEADERS
PROGRAMOBJECTS=$OBJECTS

PROGRAM=$PROJECT_NAME.\$(shell arch)

all: \$(PROGRAM)

obj/%.o: src/%.$FILE_EXTENSION \$(HEADERS)
	\$(COMPILER) -c -o \$@ \$< \$(COMPILEFLAGS) -fPIC

\$(PROGRAM): \$(PROGRAMOBJECTS)
	\$(COMPILER) -o \$(PROGRAM) \$(PROGRAMOBJECTS) \$(LINKFLAGS)
" > Makefile
}

print_with_color "cyan" "Running some tests on your tree!"

src_test
obj_test

src_code_test

if [ "$EXIT_AFTER_TESTS" = "1" ];
then
	print_with_color "red" "A test complained, stopping!"
	exit 0;
fi

print_with_color "cyan" "Tests done, generating!"

sleep 0.5s
detect_language
if [ "$LANGUAGE" != "" ];
then
	print_with_color "yellow" "Language: $LANGUAGE"
fi

if [ "$LANGUAGE" = "C" ];
then
	COMPILER="gcc"
else
	COMPILER="g++"
fi

sleep 0.5s

detect_header_files
if [ "$HEADERS" != "" ];
then
	print_with_color "magenta" "Header files: $HEADERS"
fi

sleep 0.5s

detect_objects
if [ "$OBJECTS" != "" ];
then
	print_with_color "magenta" "Objects: $OBJECTS"
else
	print_with_color "red" "No Objects! D:"
	exit -1
fi

sleep 0.5s

print_with_color "cyan" "Detecting libraries from arguments!"
detect_libraries "$@"

sleep 0.5s

print_with_color "cyan" "Generating Makefile now!"
generate_makefile

sleep 0.5s

print_with_color "cyan" "SUCCESS \\o/"
