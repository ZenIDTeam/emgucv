REM @echo off

REM POSSIBLE OPTIONS: 
REM %1%: "64", "32", "ARM"
REM %2%: "gpu", build with CUDA
REM %2%: "core", build only the core components
REM %3%: "intel_inf", build with intel compiler and using OpenVino
REM %3%: "intel", build with intel compiler
REM %3%: "inf", build with OpenVino 
REM %3%: "WindowsStore10", target UWP 
REM %3%: "vs2015", force to build with vs_2015, it may no longer work as of 2020
REM %3%: "commercial", use to enable optimization with targeting 32-bit architecture
REM %4%: "nonfree", build the nonfree module
REM %4%: "openni", build the openni module
REM %5%: "doc", this flag indicates if we should build the documentation
REM %6%: "package", this flag indicates if we should build the ".zip" and ".exe" package
REM %7%: "build", if set to "build", the script will also build the target
REM %8%: "nuget", this flag indicates if we should build the nuget package
REM %9%: Use this field for the CUDA_ARCH_BIN_OPTION if you want to specify it manually. e.g. "6.1"

SET BUILD_FOLDER=build
SET BUILD_TOOLS_FOLDER=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools

IF "%1%"=="32" GOTO ENV_x86
IF "%1%"=="64" GOTO ENV_x64
IF "%1%"=="ARM" GOTO ENV_ARM
IF "%1%"=="ARM64" GOTO ENV_ARM64

GOTO ENV_END

:ENV_x86
SET BUILD_FOLDER=%BUILD_FOLDER%_x86
ECHO "BUILDING 32bit solution in %BUILD_FOLDER%"
IF EXIST "%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvars32.bat" SET ENV_SETUP_SCRIPT=%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvars32.bat
GOTO ENV_END

:ENV_x64
SET BUILD_FOLDER=%BUILD_FOLDER%_x64
ECHO "BUILDING 64bit solution in %BUILD_FOLDER%" 
IF EXIST "%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvars64.bat" SET ENV_SETUP_SCRIPT=%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvars64.bat
GOTO ENV_END

:ENV_ARM
SET BUILD_FOLDER=%BUILD_FOLDER%_ARM
ECHO "BUILDING ARM solution in %BUILD_FOLDER%"
IF EXIST "%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvarsamd64_arm.bat" SET ENV_SETUP_SCRIPT=%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvarsamd64_arm.bat
GOTO ENV_END

:ENV_ARM64
SET BUILD_FOLDER=%BUILD_FOLDER%_ARM64
ECHO "BUILDING ARM64 solution in %BUILD_FOLDER%"
IF EXIST "%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvarsamd64_arm64.bat" SET ENV_SETUP_SCRIPT=%BUILD_TOOLS_FOLDER%\vc\Auxiliary\Build\vcvarsamd64_arm64.bat

:ENV_END
IF "%ENV_SETUP_SCRIPT%"=="" GOTO ENV_SETUP_END

call "%ENV_SETUP_SCRIPT%"

@echo on

:ENV_SETUP_END

pushd %~p0
cd ..\..
IF NOT EXIST %BUILD_FOLDER% mkdir %BUILD_FOLDER%
cd %BUILD_FOLDER%

SET NETFX_CORE=""
IF "%3%"=="WindowsPhone81" SET NETFX_CORE="TRUE" 
IF "%3%"=="WindowsStore81" SET NETFX_CORE="TRUE"
IF "%3%"=="WindowsStore10" SET NETFX_CORE="TRUE"

SET OS_MODE=
IF "%1%"=="64" SET OS_MODE= Win64
IF "%1%"=="ARM" SET OS_MODE= ARM
IF "%1%"=="ARM64" SET OS_MODE= ARM64

SET BUILD_ARCH=
IF "%1%"=="64" SET BUILD_ARCH=-A x64
IF "%1%"=="32" SET BUILD_ARCH=-A Win32
IF "%1%"=="ARM" SET BUILD_ARCH=-A ARM
IF "%1%"=="ARM64" SET BUILD_ARCH=-A ARM64

SET PROGRAMFILES_DIR_X86=%programfiles(x86)%
if NOT EXIST "%PROGRAMFILES_DIR_X86%" SET PROGRAMFILES_DIR_X86=%programfiles%
SET PROGRAMFILES_DIR=%programfiles%

REM Find CMake  
SET CMAKE="cmake.exe"
IF EXIST "%PROGRAMFILES_DIR_X86%\CMake 2.8\bin\cmake.exe" SET CMAKE="%PROGRAMFILES_DIR_X86%\CMake 2.8\bin\cmake.exe"
IF EXIST "%PROGRAMFILES_DIR_X86%\CMake\bin\cmake.exe" SET CMAKE="%PROGRAMFILES_DIR_X86%\CMake\bin\cmake.exe"
IF EXIST "%PROGRAMFILES_DIR%\CMake\bin\cmake.exe" SET CMAKE="%PROGRAMFILES_DIR%\CMake\bin\cmake.exe"
IF EXIST "%PROGRAMW6432%\CMake\bin\cmake.exe" SET CMAKE="%PROGRAMW6432%\CMake\bin\cmake.exe"

IF EXIST "CMakeCache.txt" del CMakeCache.txt

REM Find Visual Studio or Msbuild
SET VS2005="%VS80COMNTOOLS%..\IDE\devenv.com"
SET VS2008="%VS90COMNTOOLS%..\IDE\devenv.com"
SET VS2010="%VS100COMNTOOLS%..\IDE\devenv.com"
SET VS2012="%VS110COMNTOOLS%..\IDE\devenv.com"
SET VS2013="%VS120COMNTOOLS%..\IDE\devenv.com"
SET VS2015="%VS140COMNTOOLS%..\IDE\devenv.com"

FOR /F "tokens=* USEBACKQ" %%F IN (`..\miscellaneous\vswhere.exe -version [15.0^,16.0^) -property installationPath`) DO SET VS2017_DIR=%%F
SET VS2017="%VS2017_DIR%\Common7\IDE\devenv.com" 

FOR /F "tokens=* USEBACKQ" %%F IN (`..\miscellaneous\vswhere.exe -version [16.0^,17.0^) -property installationPath`) DO SET VS2019_DIR=%%F
SET VS2019="%VS2019_DIR%\Common7\IDE\devenv.com"

FOR /F "tokens=* USEBACKQ" %%F IN (`..\miscellaneous\vswhere.exe -products * -property installationPath`) DO SET VS_BUILDTOOLS=%%F

IF EXIST "%windir%\Microsoft.NET\Framework\v3.5\MSBuild.exe" SET MSBUILD35=%windir%\Microsoft.NET\Framework\v3.5\MSBuild.exe
IF EXIST "%windir%\Microsoft.NET\Framework64\v3.5\MSBuild.exe" SET MSBUILD35=%windir%\Microsoft.NET\Framework64\v3.5\MSBuild.exe
IF EXIST "%windir%\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe" SET MSBUILD40=%windir%\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe
IF EXIST "%BUILD_TOOLS_FOLDER%\MSBuild\Current\Bin\MSBuild.exe" SET MSBUILD_BUILDTOOLS=%BUILD_TOOLS_FOLDER%\MSBuild\Current\Bin\MSBuild.exe

IF EXIST "%MSBUILD35%" SET DEVENV="%MSBUILD35%"
IF EXIST "%MSBUILD40%" SET DEVENV="%MSBUILD40%"
IF EXIST "%MSBUILD_BUILDTOOLS%" SET DEVENV="%MSBUILD_BUILDTOOLS%"
IF EXIST %VS2005% SET DEVENV=%VS2005% 
IF EXIST %VS2008% SET DEVENV=%VS2008%
IF EXIST %VS2010% SET DEVENV=%VS2010%
IF "%4%"=="openni" GOTO SET_BUILD_TYPE
IF EXIST %VS2012% SET DEVENV=%VS2012%
IF EXIST %VS2013% SET DEVENV=%VS2013%
IF EXIST %VS2015% SET DEVENV=%VS2015%

REM CUDA 8.5 only support VS2015, if we target GPU we will stop checking for newer version of Visual Studio
REM IF "%2%"=="gpu" GOTO SET_BUILD_TYPE

REM For windows phone or store 81 build we should use VS2015
IF "%3%"=="WindowsPhone81" GOTO SET_BUILD_TYPE
IF "%3%"=="WindowsPhone81" GOTO SET_BUILD_TYPE

REM Only check for VS2017 if there are no other suitable Visual Studio installation
REM We may default to VS2017 once CUDA 9 supports VS2017
REM IF EXIST %DEVENV% GOTO SET_BUILD_TYPE

IF "%3%"=="vs2015" GOTO SET_BUILD_TYPE

IF EXIST %VS2017% SET DEVENV=%VS2017%
REM CUDA 9 only support VS2017, if we target GPU we will stop checking for newer version of Visual Studio

REM Intel compiler is not compatible with VS2019 16.2, if we are compiling with Intel compiler, skip VS2019
REM IF "%3%"=="intel" GOTO SET_BUILD_TYPE
REM IF "%3%"=="intel_inf" GOTO SET_BUILD_TYPE

IF EXIST %VS2019% SET DEVENV=%VS2019%

:SET_BUILD_TYPE
IF %DEVENV%=="%MSBUILD35%" SET BUILD_TYPE=/property:Configuration=Release
IF %DEVENV%=="%MSBUILD40%" SET BUILD_TYPE=/property:Configuration=Release
IF %DEVENV%=="%MSBUILD_BUILDTOOLS%" SET BUILD_TYPE=/property:Configuration=Release
IF %DEVENV%==%VS2005% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2008% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2010% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2012% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2013% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2015% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2017% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2019% SET BUILD_TYPE=/Build Release

IF %DEVENV%=="%MSBUILD35%" SET CMAKE_CONF="Visual Studio 12 2005%OS_MODE%"
IF %DEVENV%=="%MSBUILD40%" SET CMAKE_CONF="Visual Studio 16" %BUILD_ARCH%
IF %DEVENV%=="%MSBUILD_BUILDTOOLS%" SET CMAKE_CONF="Visual Studio 16" %BUILD_ARCH%
IF %DEVENV%==%VS2005% SET CMAKE_CONF="Visual Studio 8 2005%OS_MODE%"
IF %DEVENV%==%VS2008% SET CMAKE_CONF="Visual Studio 9 2008%OS_MODE%"
IF %DEVENV%==%VS2010% SET CMAKE_CONF="Visual Studio 10%OS_MODE%"
IF %DEVENV%==%VS2012% SET CMAKE_CONF="Visual Studio 11%OS_MODE%"
IF %DEVENV%==%VS2013% SET CMAKE_CONF="Visual Studio 12%OS_MODE%"
IF %DEVENV%==%VS2015% SET CMAKE_CONF="Visual Studio 14%OS_MODE%"
IF %DEVENV%==%VS2017% SET CMAKE_CONF="Visual Studio 15%OS_MODE%"
IF %DEVENV%==%VS2019% SET CMAKE_CONF="Visual Studio 16" %BUILD_ARCH%

REM Setup common flags
SET CMAKE_CONF_FLAGS= -G %CMAKE_CONF% ^
-DBUILD_DOCS:BOOL=FALSE ^
-DBUILD_TESTS:BOOL=FALSE ^
-DBUILD_opencv_apps:BOOL=FALSE ^
-DBUILD_opencv_python2:BOOL=FALSE ^
-DEMGU_ENABLE_SSE:BOOL=TRUE ^
-DBUILD_WITH_DEBUG_INFO:BOOL=FALSE ^
-DBUILD_WITH_STATIC_CRT:BOOL=FALSE ^
-DWITH_OPENGL:BOOL=OFF ^
-DHB_HAVE_FREETYPE:BOOL=TRUE ^
-DCMAKE_DISABLE_FIND_PACKAGE_BZip2:BOOL=TRUE ^
-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB:BOOL=TRUE ^
-DCMAKE_DISABLE_FIND_PACKAGE_PNG:BOOL=TRUE ^
-DVIDEOIO_PLUGIN_LIST:STRING="ffmpeg"

REM For Freetype, removed the "d" postfix for debug mode.
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DDISABLE_FORCE_DEBUG_POSTFIX:BOOL=TRUE 

REM Setup the contrib modules
IF "%2%"=="core" GOTO CONFIG_CORE

:CONFIG_FULL
SET OPENCV_EXTRA_MODULES_DIR=%cd%\..\opencv_contrib\modules
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DOPENCV_EXTRA_MODULES_PATH:String="%OPENCV_EXTRA_MODULES_DIR:\=/%" 
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEMGU_CV_WITH_TESSERACT:BOOL=TRUE 
GOTO END_CONFIG_CORE

:CONFIG_CORE
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEMGU_CV_WITH_TESSERACT:BOOL=FALSE 
:END_CONFIG_CORE

SET BUILD_TYPE=OPEN_SOURCE

REM GPU performance test on windows cause compilation error, skipping it now
IF "%2%"=="gpu" GOTO NO_PERFORMANCE_TEST

REM Intel compiler performance test on windows cause compilation error, skipping it now
IF "%3%"=="intel" GOTO NO_PERFORMANCE_TEST
IF "%3%"=="intel_inf" GOTO NO_PERFORMANCE_TEST

REM NETFX_CORE performance test cause compilation issue, skipping it now
IF %NETFX_CORE%=="" GOTO WITH_PERFORMANCE_TEST

:NO_PERFORMANCE_TEST
REM BUILD WITHOUT PERFORMANCE TEST
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DBUILD_opencv_ts:BOOL=OFF ^
-DBUILD_PERF_TESTS:BOOL=OFF 
GOTO END_PERFORMANCE_TEST

:WITH_PERFORMANCE_TEST
REM BUDILD WITH PERFORMANCE TEST 
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DBUILD_opencv_ts:BOOL=ON ^
-DBUILD_PERF_TESTS:BOOL=ON 

:END_PERFORMANCE_TEST

IF "%1%"=="ARM" GOTO WITH_ARM
IF "%1%"=="ARM64" GOTO WITH_ARM
GOTO END_WITH_ARM

:WITH_ARM
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCV_ENABLE_INTRINSICS:BOOL=FALSE 
:END_WITH_ARM

IF NOT "%4%"=="openni" GOTO END_OF_OPENNI
:WITH_OPENNI
SET OPENNI_LIB_DIR=%OPEN_NI_LIB%
IF "%OS_MODE%"==" Win64" SET OPENNI_LIB_DIR=%OPEN_NI_LIB64%
SET OPENNI_PS_BIN_DIR=%OPENNI_LIB_DIR%\..\..\PrimeSense\Sensor\Bin
IF "%OS_MODE%"==" Win64" SET OPENNI_PS_BIN_DIR=%OPENNI_LIB_DIR%\..\..\PrimeSense\Sensor\Bin64

IF EXIST "%OPENNI_LIB_DIR%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_OPENNI:BOOL=TRUE ^
-DOPENNI_INCLUDE_DIR:String="%OPEN_NI_INCLUDE:\=/%" ^
-DOPENNI_LIB_DIR:String="%OPENNI_LIB_DIR:\=/%" ^
-DOPENNI_PRIME_SENSOR_MODULE_BIN_DIR:String="%OPENNI_PS_BIN_DIR:\=/%"
:END_OF_OPENNI

IF NOT "%4%"=="nonfree" GOTO END_OF_NONFREE
:WITH_NONFREE
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DOPENCV_ENABLE_NONFREE:BOOL=TRUE 
:END_OF_NONFREE


IF "%5%"=="doc" ^
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEMGU_CV_DOCUMENTATION_BUILD:BOOL=TRUE 
REM IF "%5%"=="htmldoc" ^
REM SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEMGU_CV_DOCUMENTATION_BUILD:BOOL=TRUE 


cd ..
cd eigen
IF NOT EXIST %BUILD_FOLDER% mkdir %BUILD_FOLDER%
cd %BUILD_FOLDER%
%CMAKE% -G %CMAKE_CONF% -DCMAKE_BUILD_TYPE:STRING="Release" ..
cd ..
cd ..
SET EIGEN_DIR=%cd%\eigen\%BUILD_FOLDER%
cd %BUILD_FOLDER%

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEigen3_DIR:STRING=%EIGEN_DIR% 

REM echo %NETFX_CORE%
IF %NETFX_CORE%=="TRUE" GOTO NETFX_CORE
:NONE_NETFX_CORE
cd ..
cd vtk
IF NOT EXIST %BUILD_FOLDER% mkdir %BUILD_FOLDER%
cd %BUILD_FOLDER%
%CMAKE% -G %CMAKE_CONF% -DVTK_DATA_EXCLUDE_FROM_ALL:BOOL=TRUE -DBUILD_TESTING:BOOL=FALSE -DBUILD_SHARED_LIBS:BOOL=FALSE -DCMAKE_BUILD_TYPE:STRING="Release" ..
%CMAKE% --build . --config Release --parallel
cd ..
cd ..
SET VTK_DIR=%cd%\vtk\%BUILD_FOLDER%
SET VTK_DIR=%VTK_DIR%
cd %BUILD_FOLDER%

SET CMAKE_CONF_FLAGS=^
%CMAKE_CONF_FLAGS% -DVTK_DIR:String=%VTK_DIR%

GOTO END_OF_NETFX_CORE
:NETFX_CORE

:END_OF_NETFX_CORE


IF NOT "%2%"=="gpu" GOTO WITHOUT_GPU
REM IF %DEVENV%==%VS2012% GOTO END_OF_GPU
REM IF %DEVENV%==%VS2013% GOTO END_OF_GPU

:WITH_GPU
REM SET CUDA_HOST_COMPILER=%DEVENV%
IF %DEVENV%==%VS2008% SET CUDA_HOST_COMPILER=%VS90COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2010% SET CUDA_HOST_COMPILER=%VS100COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2012% SET CUDA_HOST_COMPILER=%VS110COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2013% SET CUDA_HOST_COMPILER=%VS120COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2015% SET CUDA_HOST_COMPILER=%VS140COMNTOOLS%..\..\VC\bin\cl.exe

for /d %%i in ( "%VS2017_DIR%\VC\Tools\MSVC\*" ) do SET VS2017_CUDA_HOST_COMPILER=%%i\bin\Hostx64\x64\cl.exe
IF %DEVENV%==%VS2017% SET CUDA_HOST_COMPILER=%VS2017_CUDA_HOST_COMPILER%

for /d %%i in ( "%VS2019_DIR%\VC\Tools\MSVC\*" ) do SET VS2019_CUDA_HOST_COMPILER=%%i\bin\Hostx64\x64\cl.exe
IF %DEVENV%==%VS2019% SET CUDA_HOST_COMPILER=%VS2019_CUDA_HOST_COMPILER%

for /d %%i in ( "%BUILD_TOOLS_FOLDER%\VC\Tools\MSVC\14.2*" ) do SET BUILDTOOLS_CUDA_HOST_COMPILER=%%i\bin\Hostx64\x64\cl.exe
IF %DEVENV%=="%MSBUILD_BUILDTOOLS%" SET CUDA_HOST_COMPILER=%BUILDTOOLS_CUDA_HOST_COMPILER%

REM Find cuda. Use latest Cuda release for 64 bit and Cuda 6.5 for 32bit
REM We cannot use latest Cuda release for 32 bit because the 32bit version of npp has been depreciated from Cuda 7
IF "%OS_MODE%"==" Win64" GOTO WITH_GPU_64

:WITH_GPU_32
SET CUDA_SDK_DIR=%CUDA_PATH_V6_5%
SET CUDA_64_MODE=-DCUDA_64_BIT_DEVICE_CODE:BOOL=FALSE
GOTO END_GPU_ARCH

:WITH_GPU_64
REM If you are using CUDA 9 with Open CV 3.3 release you will need to create an nppi.lib file with instructions from here:
REM https://stackoverflow.com/questions/45525377/installing-opencv-3-3-0-with-contrib-modules-using-cmake-cuda-9-0-rc-and-visual

SET CUDA_SDK_DIR=%CUDA_PATH%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V11_0%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V10_1%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V10_0%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V9_1%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V9_0%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V8_0%
IF NOT EXIST "%CUDA_SDK_DIR%" SET CUDA_SDK_DIR=%CUDA_PATH_V7_5%
SET CUDA_64_MODE=-DCUDA_64_BIT_DEVICE_CODE:BOOL=TRUE
SET CUDA_NVCUVENC_DIR="%PROGRAMFILES_DIR%\NVIDIA GPU Computing Toolkit\CUDA\Video_Codec_SDK_10.0.26"
IF EXIST %CUDA_NVCUVENC_DIR% SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DCUDA_nvcuvenc_LIBRARY:String=%CUDA_NVCUVENC_DIR:\=/% ^
-DWITH_NVCUVID:BOOL=TRUE
:END_GPU_ARCH


REM IF "%CUDA_SDK_DIR%"=="%CUDA_PATH_V9_1%" IF %DEVENV%==%VS2017% GOTO START_FIND_CL
REM IF "%CUDA_SDK_DIR%"=="%CUDA_PATH_V9_0%" IF %DEVENV%==%VS2017% GOTO START_FIND_CL

REM GOTO END_FIND_CL

REM :START_FIND_CL
REM SET MSVC_14_11=%VS2017_DIR%\VC\Tools\MSVC\14.11.25503\bin\Hostx64\x64\cl.exe
REM SET MSVC_14_12=%VS2017_DIR%\VC\Tools\MSVC\14.14.12.25827\bin\Hostx64\x64\cl.exe
REM CUDA 9.0 or 9.1 is not compatible with MSVC_14_12 in VS2017, forcing it to use 14.11
REM IF EXIST "%MSVC_14_11%" SET CUDA_HOST_COMPILER=%MSVC_14_11%
REM pushd "%VS2017_DIR%\VC\Auxiliary\Build\"
REM call vcvars64.bat -vcvars_ver=14.11  
REM popd
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DCUDA_HOST_COMPILER:String="%CUDA_HOST_COMPILER%" 
REM -DCUDA_HOST_COMPILER:String="%CUDA_HOST_COMPILER:\=/%" 

REM :END_FIND_CL

IF NOT "%9%"=="" GOTO GPU_ARCH_BIN_SPECIFIED
SET CUDA_ARCH_BIN_OPTION=""
IF EXIST "%CUDA_SDK_DIR%" SET CUDA_ARCH_BIN_OPTION="6.0 6.1 7.0"
IF "%CUDA_SDK_DIR%" == "%CUDA_PATH_V8_0%" SET CUDA_ARCH_BIN_OPTION="6.0 6.1"
IF "%CUDA_SDK_DIR%" == "%CUDA_PATH_V9_0%" SET CUDA_ARCH_BIN_OPTION="6.0 6.1 7.0"
IF "%CUDA_SDK_DIR%" == "%CUDA_PATH_V9_1%" SET CUDA_ARCH_BIN_OPTION="6.0 6.1 7.0"
IF "%CUDA_SDK_DIR%" == "%CUDA_PATH_V10_0%" SET CUDA_ARCH_BIN_OPTION="6.0 6.1 7.0 7.5"
IF "%CUDA_SDK_DIR%" == "%CUDA_PATH_V10_1%" SET CUDA_ARCH_BIN_OPTION="6.0 6.1 7.0 7.5"
IF "%CUDA_SDK_DIR%" == "%CUDA_PATH_V11_0%" SET CUDA_ARCH_BIN_OPTION="5.2 6.1 7.5 8.6"
GOTO END_GPU_ARCH_BIN

:GPU_ARCH_BIN_SPECIFIED
SET CUDA_ARCH_BIN_OPTION="%9%" 

:END_GPU_ARCH_BIN

IF EXIST "%CUDA_SDK_DIR%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
%CUDA_64_MODE% ^
-DWITH_CUDA:BOOL=TRUE ^
-DCUDA_VERBOSE_BUILD:BOOL=TRUE ^
-DCUDA_TOOLKIT_ROOT_DIR:String="%CUDA_SDK_DIR:\=/%" ^
-DCUDA_SDK_ROOT_DIR:String="%CUDA_SDK_DIR:\=/%" ^
-DWITH_CUBLAS:BOOL=TRUE ^
-DBUILD_SHARED_LIBS:BOOL=TRUE ^
-DOPENCV_SKIP_DLLMAIN_GENERATION=ON ^
-DCUDA_ARCH_BIN:STRING=%CUDA_ARCH_BIN_OPTION%

GOTO END_OF_GPU

:WITHOUT_GPU
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_CUDA:BOOL=FALSE ^
-DBUILD_SHARED_LIBS:BOOL=FALSE 

:END_OF_GPU

IF "%3%"=="inf" GOTO WITH_OPENVINO
IF "%3%"=="intel_inf" GOTO WITH_OPENVINO

GOTO WITHOUT_OPENVINO

:WITH_OPENVINO
REM use OpenVINO if possible
SET OPENVINO_DIR=
REM IF EXIST "C:\Intel\computer_vision_sdk_2018.3.343" SET OPENVINO_DIR=C:\Intel\computer_vision_sdk_2018.3.343
REM IF EXIST "C:\Intel\computer_vision_sdk_2018.5.445" SET OPENVINO_DIR=C:\Intel\computer_vision_sdk_2018.5.445
IF EXIST "%PROGRAMFILES_DIR_X86%\IntelSWTools\openvino" SET OPENVINO_DIR=%PROGRAMFILES_DIR_X86%\IntelSWTools\openvino
IF EXIST "%PROGRAMFILES_DIR_X86%\Intel\openvino_2021" SET OPENVINO_DIR=%PROGRAMFILES_DIR_X86%\Intel\openvino_2021
IF EXIST "%PROGRAMFILES_DIR_X86%\Intel\openvino_2021" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DINF_ENGINE_RELEASE:STRING="2021010000"
IF NOT EXIST "%OPENVINO_DIR%" GOTO WITHOUT_OPENVINO

REM GOTO WITHOUT_OPENVINO

REM SET INTEL_CVSDK_DIR=%OPENVINO_DIR%\deployment_tools\inference_engine
REM -DINF_ENGINE_RELEASE="2018030343" ^
call "%OPENVINO_DIR%\bin\setupvars.bat"
@echo on

SET CMAKE_CONF_FLAGS=^
-DWITH_INF_ENGINE:BOOL=TRUE ^
-DENABLE_CXX11=ON ^
%CMAKE_CONF_FLAGS%

REM -DINF_ENGINE_INCLUDE_DIRS="%OPENVINO_DIR:\=/%/deployment_tools/inference_engine/include" ^
REM -DINF_ENGINE_LIB_DIRS="%OPENVINO_DIR:\=/%/deployment_tools/inference_engine/lib/intel64" ^

SET BUILD_TYPE=COMMERCIAL

GOTO END_OF_OPENVINO

:WITHOUT_OPENVINO
SET CMAKE_CONF_FLAGS=^
-DWITH_INF_ENGINE:BOOL=FALSE ^
%CMAKE_CONF_FLAGS%
:END_OF_OPENVINO


IF "%3%"=="intel" GOTO INTEL_COMPILER
IF "%3%"=="intel_inf" GOTO INTEL_COMPILER

:NOT_INTEL_COMPILER

IF "%3%"=="commercial" SET BUILD_TYPE=COMMERCIAL

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DWITH_LAPACK:BOOL=FALSE 
GOTO VISUAL_STUDIO

:INTEL_COMPILER
REM Find Intel Compiler 
SET INTEL_COMPILER_DIR=%ICPP_COMPILER20%
SET INTEL_DIR=%INTEL_COMPILER_DIR%bin
SET INTEL_ENV=%INTEL_DIR%\iclvars.bat
SET INTEL_ICL=%INTEL_DIR%\ia32\icl.exe
IF "%OS_MODE%"==" Win64" SET INTEL_ICL=%INTEL_DIR%\intel64\icl.exe
SET INTEL_TBB=%INTEL_COMPILER_DIR%tbb\include

REM SET INTEL_MKL_ROOT=%INTEL_COMPILER_DIR%mkl

SET INTEL_ARCH=ia32
IF "%OS_MODE%"==" Win64" SET INTEL_ARCH=intel64
SET INTEL_DEV_ENV=""
IF %DEVENV%==%VS2012% SET INTEL_DEV_ENV=vs2012
IF %DEVENV%==%VS2013% SET INTEL_DEV_ENV=vs2013
IF %DEVENV%==%VS2015% SET INTEL_DEV_ENV=vs2015
IF %DEVENV%==%VS2017% SET INTEL_DEV_ENV=vs2017
IF %DEVENV%==%VS2019% SET INTEL_DEV_ENV=vs2019
call "%INTEL_COMPILER_DIR%tbb\bin\tbbvars.bat" %INTEL_ARCH% %INTEL_DEV_ENV%
REM call "%INTEL_COMPILER_DIR%mkl\bin\mklvars.bat" %INTEL_ARCH% %INTEL_DEV_ENV%

REM initiate the compiler enviroment
@echo on

IF EXIST "%INTEL_DIR%" SET BUILD_TYPE=COMMERCIAL

IF EXIST "%INTEL_DIR%" SET CMAKE_CONF_FLAGS=^
-DWITH_TBB:BOOL=TRUE ^
-DMKL_WITH_TBB:BOOL=TRUE ^
-DTBB_INCLUDE_DIR:String="%INTEL_TBB:\=/%" ^
-DCV_ICC:BOOL=TRUE ^
%CMAKE_CONF_FLAGS%

REM -DMKL_ROOT_DIR:String="%INTEL_MKL_ROOT:\=/%" 
REM IF NOT "%2%"=="gpu" GOTO END_OF_INTEL_GPU
REM SET CUDA_HOST_COMPILER=%VS110COMNTOOLS%..\..\VC\bin
REM IF "%OS_MODE%"==" Win64" SET CUDA_HOST_COMPILER=%CUDA_HOST_COMPILER%\amd64
REM IF EXIST %VS2012% SET CMAKE_CONF_FLAGS=-DCUDA_HOST_COMPILER:String="%CUDA_HOST_COMPILER%" %CMAKE_CONF_FLAGS%
REM IF "%OS_MODE%"==" Win64" SET CMAKE_CONF_FLAGS=-DCUDA_64_BIT_DEVICE_CODE:BOOL=ON %CMAKE_CONF_FLAGS%
REM :END_OF_INTEL_GPU

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_OPENCL:BOOL=TRUE ^
-DWITH_MSMF:BOOL=TRUE

GOTO RUN_CMAKE

:VISUAL_STUDIO

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% %IPP_BUILD_FLAGS% 
 
IF "%3%"=="WindowsStore10" GOTO CONFIGURE_WINDOWS_STORE_10

REM Windows Desktop Build

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_OPENCL:BOOL=TRUE ^
-DWITH_MSMF:BOOL=TRUE
GOTO RUN_CMAKE


:CONFIGURE_WINDOWS_STORE_10
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_NAME:String="WindowsStore" 
IF %DEVENV%==%VS2017% SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_VERSION:String="10.0.14393.0"
IF %DEVENV%==%VS2019% SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_VERSION:String="10.0.18362.0"
IF %DEVENV%=="%MSBUILD_BUILDTOOLS%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_VERSION:String="10.0.18362.0"
REM IF %DEVENV%==%VS2019% SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_VERSION:String="10.0.17763.0"

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DNETFX_CORE:BOOL=TRUE ^
-DWITH_DIRECTX:BOOL=FALSE ^
-DWITH_OPENEXR:BOOL=FALSE ^
-DWITH_TIFF:BOOL=FALSE ^
-DEMGU_CV_WITH_TIFF:BOOL=FALSE ^
-DWITH_PNG:BOOL=TRUE ^
-DWITH_DSHOW:BOOL=FALSE ^
-DWITH_WIN32UI:BOOL=FALSE ^
-DWITH_VFW:BOOL=FALSE ^
-DWITH_MSMF:BOOL=FALSE ^
-DWITH_FFMPEG:BOOL=FALSE ^
-DWITH_OPENCL:BOOL=FALSE ^
-DEMGU_ENABLE_SSE:BOOL=FALSE 

@echo on
:RUN_CMAKE

IF "%BUILD_TYPE%"=="COMMERCIAL" GOTO CONFIGURE_COMMERCIAL
GOTO CONFIGURE_OPENSOURCE

:CONFIGURE_COMMERCIAL
SET IPP_BUILD_FLAGS=-DWITH_IPP:BOOL=TRUE
SET CPU_DISPATCH_FLAGS=-DCPU_DISPATCH:STRING=SSE4_1;SSE4_2;AVX;AVX2
GOTO END_CONFIG_COMMERCIAL_OR_OPENSOURCE

:CONFIGURE_OPENSOURCE
SET IPP_BUILD_FLAGS=-DWITH_IPP:BOOL=FALSE 
SET CPU_DISPATCH_FLAGS=-DCPU_DISPATCH:STRING=""

:END_CONFIG_COMMERCIAL_OR_OPENSOURCE
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% %IPP_BUILD_FLAGS% %CPU_DISPATCH_FLAGS%
%CMAKE% %CMAKE_CONF_FLAGS% ..\ 

:BUILD
IF NOT "%7%"=="build" GOTO END

SET CMAKE_BUILD_TARGET=cvextern
IF NOT "%6%"=="package" GOTO CHECK_DOC_BUILD
SET CMAKE_BUILD_TARGET=%CMAKE_BUILD_TARGET% PACKAGE
:CHECK_DOC_BUILD
IF NOT "%5%"=="doc" GOTO CHECK_NUGET_BUILD
SET CMAKE_BUILD_TARGET=%CMAKE_BUILD_TARGET% Emgu.CV.Document
:CHECK_NUGET_BUILD
IF NOT "%8%"=="nuget" GOTO END_SET_BUILD_TARGET
SET CMAKE_BUILD_TARGET=%CMAKE_BUILD_TARGET% Emgu.CV.runtime.windows.nuget
:END_SET_BUILD_TARGET
REM echo CMAKE_BUILD_TARGET=%CMAKE_BUILD_TARGET% Emgu.CV.nuget

REM Don't build with parallel at this time. Multiple Example demo projects building in parallel will results in build errors.
REM %CMAKE% --build . --config Release --parallel --target %CMAKE_BUILD_TARGET%
%CMAKE% --build . --config Release --target %CMAKE_BUILD_TARGET%

REM IF "%2%"=="gpu" ^
REM call %DEVENV% %BUILD_TYPE% emgucv.sln /project Emgu.CV.CUDA.nuget 

:END
popd
