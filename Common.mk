SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

SPACE1=
SPACE=$(SPACE1) $(SPACE1)

TARGET_PLATFORMS = linux32 linux64 msvc32 osx ios32 ios64 iossim android html mingw32 mingw64

# Directories

THIRD_PARTY_DIR         = third_party
SDL_DIR          = $(THIRD_PARTY_DIR)/SDL2-2.0.8
LUA51_DIR        = $(THIRD_PARTY_DIR)/lua-5.1.5
LUA52_DIR        = $(THIRD_PARTY_DIR)/lua-5.2.4
LUA53_DIR        = $(THIRD_PARTY_DIR)/lua-5.3.1
LUAJIT_DIR       = $(THIRD_PARTY_DIR)/LuaJIT-2.0.4
ANGLE_DIR        = $(THIRD_PARTY_DIR)/angle-chrome_m34
GLM_DIR          = $(THIRD_PARTY_DIR)/glm-0.9.7.1
FT2_DIR          = $(THIRD_PARTY_DIR)/freetype-2.5.5
STB_DIR		 = $(THIRD_PARTY_DIR)/stb
KISSFFT_DIR	 = $(THIRD_PARTY_DIR)/kiss_fft130
TINYMT_DIR	 = $(THIRD_PARTY_DIR)/tinymt-1.0.3
SIMPLEOPT_DIR    = $(THIRD_PARTY_DIR)/simpleopt

# Host settings (this is the *build* host, not the host we want to run on)

PATH_SEP = :

UNAME := $(shell uname)
ifneq (,$(findstring W32,$(UNAME)))
  HOST_PLATFORM = msvc32
  IS_WINDOWS = yes
  PATH_SEP = ;
else ifneq (,$(findstring Linux,$(UNAME)))
  UNAME_A := $(shell uname -a)
  ifneq (,$(findstring x86_64,$(UNAME_A)))
    HOST_PLATFORM = linux64
  else
    HOST_PLATFORM = linux32
  endif
else ifneq (,$(findstring Darwin,$(UNAME)))
  HOST_PLATFORM = osx
endif

ifndef HOST_PLATFORM
  $(error Unrecognised host)
endif

# Target settings (this is the target platform we want to run on)

-include $(SELF_DIR)settings

ifdef TARGET
  ifneq (,$(findstring .debug,$(TARGET)))
    GRADE = debug
    TARGET_PLATFORM = $(subst .debug,,$(TARGET))
  else ifneq (,$(findstring .release,$(TARGET)))
    GRADE = release
    TARGET_PLATFORM = $(subst .release,,$(TARGET))
  else
    $(error Unrecognised TARGET: $(TARGET))
  endif
else
  TARGET_PLATFORM = $(HOST_PLATFORM)
  GRADE = release
  TARGET = $(TARGET_PLATFORM).$(GRADE)
endif

ifndef LUAVM
  LUAVM = lua51
endif

SDL_ALIB = $(BUILD_LIB_DIR)/libsdl$(ALIB_EXT)
ANGLE_ALIB = $(BUILD_LIB_DIR)/libangle$(ALIB_EXT)
ANGLE_WIN_PREBUILT = $(BUILD_LIB_DIR)/angle-win-prebuilt.date
LUA51_ALIB = $(BUILD_LIB_DIR)/liblua51$(ALIB_EXT)
LUA52_ALIB = $(BUILD_LIB_DIR)/liblua52$(ALIB_EXT)
LUA53_ALIB = $(BUILD_LIB_DIR)/liblua53$(ALIB_EXT)
LUAJIT_ALIB = $(BUILD_LIB_DIR)/libluajit$(ALIB_EXT)
LUAVM_ALIB = $(BUILD_LIB_DIR)/lib$(LUAVM)$(ALIB_EXT)
FT2_ALIB = $(BUILD_LIB_DIR)/libft2$(ALIB_EXT)
STB_ALIB = $(BUILD_LIB_DIR)/libstb$(ALIB_EXT)
KISSFFT_ALIB = $(BUILD_LIB_DIR)/libkissfft$(ALIB_EXT)
TINYMT_ALIB = $(BUILD_LIB_DIR)/libtinymt$(ALIB_EXT)
SIMPLEGLOB_H = $(BUILD_INC_DIR)/SimpleGlob.h

SRC_DIR = src
BUILD_BASE_DIR = builds/$(TARGET_PLATFORM)/$(LUAVM)/$(GRADE)
BUILD_BIN_DIR = $(BUILD_BASE_DIR)/bin
BUILD_OBJ_DIR = $(BUILD_BASE_DIR)/obj
BUILD_LIB_DIR = $(BUILD_BASE_DIR)/lib
BUILD_INC_DIR = $(BUILD_BASE_DIR)/include

BUILD_DIRS = $(BUILD_BIN_DIR) $(BUILD_LIB_DIR) $(BUILD_INC_DIR) $(BUILD_OBJ_DIR)

ifeq (,$(wildcard $(THIRD_PARTY_DIR)/GoogleMobileAds.framework))
  GOOGLE_ADS_FRAMEWORK_OPT=
else
  GOOGLE_ADS=1
  GOOGLE_ADS_FRAMEWORK_OPT=-Wl,-framework,GoogleMobileAds
endif

EXE_EXT = 
ALIB_EXT = .a
OBJ_EXT = .o
DEF_OPT = -D
INCLUDE_OPT = -I
CC = gcc
HOSTCC = gcc
CPP = g++
LINK = g++
AR = ar
AR_OPTS = rcus
AR_OUT_OPT =
XCFLAGS = -Wall -Werror -pthread -fno-strict-aliasing
XLDFLAGS = -ldl -lm -lrt -pthread
LUA_CFLAGS = -DLUA_COMPAT_ALL
LUAJIT_FLAGS = 
OBJ_OUT_OPT = -o
EXE_OUT_OPT = -o
NOLINK_OPT = -c
C99_OPT = -std=c99

EMSCRIPTEN_LIBS = html/library_sdl.js
EMSCRIPTEN_LIBS_OPTS = $(patsubst %,--js-library %,$(EMSCRIPTEN_LIBS))
EMSCRIPTEN_EXPORTS_OPT = -s EXPORTED_FUNCTIONS="['_main', '_am_emscripten_run', '_am_emscripten_run_waiting', '_am_emscripten_pause', '_am_emscripten_resume', '_am_emscripten_resize']"

TARGET_CFLAGS=-ffast-math

SDL_PREBUILT_SUBDIR=$(TARGET_PLATFORM)

ifeq (,$(wildcard $(THIRD_PARTY_DIR)/steamworks_sdk))
  STEAMWORKS_LIB=
  STEAMWORKS_LIB_DIR=
  STEAMWORKS_INC_DIR=
  STEAMWORKS_DEP=
  STEAMWORKS_LINK_OPT=
else
  STEAMWORKS=1
  ifeq ($(TARGET_PLATFORM),msvc32)
      STEAMWORKS_LIB=$(BUILD_LIB_DIR)/libsteam_api.lib
      STEAMWORKS_LIB_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/redistributable_bin
      STEAMWORKS_INC_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/public
      STEAMWORKS_DEP=steam_api
  else ifeq ($(TARGET_PLATFORM),linux64)
      STEAMWORKS_LIB=$(BUILD_BIN_DIR)/libsteam_api.so
      XLDFLAGS+=-L$(BUILD_BIN_DIR) -lsteam_api 
      STEAMWORKS_LIB_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/redistributable_bin/linux64
      STEAMWORKS_INC_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/public
  else ifeq ($(TARGET_PLATFORM),linux32)
      STEAMWORKS_LIB=$(BUILD_BIN_DIR)/libsteam_api.so
      XLDFLAGS+=-L$(BUILD_BIN_DIR) -lsteam_api 
      STEAMWORKS_LIB_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/redistributable_bin/linux32
      STEAMWORKS_INC_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/public
  else ifeq ($(TARGET_PLATFORM),osx)
      STEAMWORKS_LIB=$(BUILD_BIN_DIR)/libsteam_api.dylib
      STEAMWORKS_LINK_OPT=-L$(BUILD_BIN_DIR) -lsteam_api 
      STEAMWORKS_LIB_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/redistributable_bin/osx32
      STEAMWORKS_INC_DIR=$(THIRD_PARTY_DIR)/steamworks_sdk/public
  endif
endif

# Adjust flags for target
ifeq ($(TARGET_PLATFORM),osx)
  CC = clang
  CPP = clang++
  LINK = clang++
  XCFLAGS += -ObjC++
  TARGET_CFLAGS += -m64 -arch x86_64
  XLDFLAGS = -lm -liconv $(STEAMWORKS_LINK_OPT) -Wl,-framework,OpenGL -Wl,-framework,ForceFeedback -lobjc \
  	     -Wl,-framework,Cocoa -Wl,-framework,Carbon -Wl,-framework,IOKit \
	     -Wl,-framework,CoreAudio -Wl,-framework,AudioToolbox -Wl,-framework,AudioUnit \
	     -Wl,-framework,AVFoundation -Wl,-framework,CoreVideo -Wl,-framework,CoreMedia \
	     -pagezero_size 10000 -image_base 100000000
  LUA_CFLAGS += -DLUA_USE_MACOSX
  MACOSX_DEPLOYMENT_TARGET=10.6
  export MACOSX_DEPLOYMENT_TARGET
else ifeq ($(TARGET_PLATFORM),ios32)
  CC = clang
  CPP = clang++
  LINK = $(CPP)
  XCODE_PATH = $(shell xcode-select --print-path)
  SDK_VERSION = $(shell xcodebuild -showsdks | grep iphoneos | sed "s/.*iphoneos//")
  SDK_PATH = $(XCODE_PATH)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDK_VERSION).sdk
  TARGET_CFLAGS += -Fthird_party -arch armv7 -isysroot $(SDK_PATH) -miphoneos-version-min=7.0
  XCFLAGS += -ObjC++
  XLDFLAGS = $(TARGET_CFLAGS) -lm -liconv -Wl,-framework,OpenGLES -lobjc \
	     -Wl,-framework,CoreAudio -Wl,-framework,AudioToolbox -Wl,-framework,MediaPlayer -Wl,-framework,MobileCoreServices \
	     -Wl,-framework,CFNetwork -Wl,-framework,CoreGraphics -Wl,-framework,SystemConfiguration \
	     -Wl,-framework,UIKit -Wl,-framework,QuartzCore -Wl,-framework,SpriteKit -Wl,-framework,StoreKit -Wl,-framework,CoreMedia \
	     -Wl,-framework,CoreMotion -Wl,-framework,Foundation -Wl,-framework,CoreTelephony \
	     -Wl,-framework,AVFoundation -Wl,-framework,CoreVideo -Wl,-framework,MessageUI -Wl,-framework,AdSupport \
	     -Wl,-framework,GLKit -Wl,-framework,GameKit $(GOOGLE_ADS_FRAMEWORK_OPT)
  LUA_CFLAGS += -DLUA_USE_POSIX -DIPHONEOS
  IOS = 1
else ifeq ($(TARGET_PLATFORM),ios64)
  CC = clang
  CPP = clang++
  LINK = $(CPP)
  XCODE_PATH = $(shell xcode-select --print-path)
  SDK_VERSION = $(shell xcodebuild -showsdks | grep iphoneos | sed "s/.*iphoneos//")
  SDK_PATH = $(XCODE_PATH)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDK_VERSION).sdk
  TARGET_CFLAGS += -Fthird_party -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=7.0
  XCFLAGS += -ObjC++
  XLDFLAGS = $(TARGET_CFLAGS) -lm -liconv -Wl,-framework,OpenGLES -lobjc \
	     -Wl,-framework,CoreAudio -Wl,-framework,AudioToolbox -Wl,-framework,MediaPlayer -Wl,-framework,MobileCoreServices \
	     -Wl,-framework,CFNetwork -Wl,-framework,CoreGraphics -Wl,-framework,SystemConfiguration \
	     -Wl,-framework,UIKit -Wl,-framework,QuartzCore -Wl,-framework,SpriteKit -Wl,-framework,StoreKit -Wl,-framework,CoreMedia \
	     -Wl,-framework,CoreMotion -Wl,-framework,Foundation -Wl,-framework,CoreTelephony -Wl,-framework,MessageUI -Wl,-framework,AdSupport \
	     -Wl,-framework,AVFoundation -Wl,-framework,CoreVideo \
	     -Wl,-framework,GLKit -Wl,-framework,GameKit $(GOOGLE_ADS_FRAMEWORK_OPT)
  LUA_CFLAGS += -DLUA_USE_POSIX -DIPHONEOS
  IOS = 1
else ifeq ($(TARGET_PLATFORM),iossim)
  CC = clang
  CPP = clang++
  LINK = $(CPP)
  XCODE_PATH = $(shell xcode-select --print-path)
  SDK_VERSION = $(shell xcodebuild -showsdks | grep iphoneos | sed "s/.*iphoneos//")
  SDK_PATH = $(XCODE_PATH)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(SDK_VERSION).sdk
  TARGET_CFLAGS += -Fthird_party -arch x86_64 -isysroot $(SDK_PATH) -miphoneos-version-min=7.0
  XCFLAGS += -ObjC++
  XLDFLAGS = $(TARGET_CFLAGS) -lm -liconv -Wl,-framework,OpenGLES -lobjc \
	     -Wl,-framework,CoreAudio -Wl,-framework,AudioToolbox -Wl,-framework,MediaPlayer -Wl,-framework,MobileCoreServices \
	     -Wl,-framework,CFNetwork -Wl,-framework,CoreGraphics -Wl,-framework,SystemConfiguration \
	     -Wl,-framework,UIKit -Wl,-framework,QuartzCore -Wl,-framework,SpriteKit -Wl,-framework,StoreKit -Wl,-framework,CoreMedia \
	     -Wl,-framework,CoreMotion -Wl,-framework,Foundation -Wl,-framework,CoreTelephony -Wl,-framework,MessageUI -Wl,-framework,AdSupport \
	     -Wl,-framework,AVFoundation -Wl,-framework,CoreVideo \
	     -Wl,-framework,GLKit -Wl,-framework,GameKit $(GOOGLE_ADS_FRAMEWORK_OPT)
  LUA_CFLAGS += -DLUA_USE_POSIX -DIPHONEOS
  IOS = 1
else ifeq ($(TARGET_PLATFORM),android)
  NDK_VER=$(NDK_HOME)/toolchains/arm-linux-androideabi-4.9
  NDK_SYSROOT=$(NDK_HOME)/platforms/android-$(NDK_ANDROID_VER)/arch-arm
  CC = $(NDK_HOME)/toolchains/llvm/prebuilt/$(NDK_HOST)/bin/clang
  CPP = $(NDK_HOME)/toolchains/llvm/prebuilt/$(NDK_HOST)/bin/clang++
  LINK = $(CPP)
  AR= $(NDK_VER)/prebuilt/$(NDK_HOST)/bin/arm-linux-androideabi-ar
  TARGET_CFLAGS += --sysroot $(NDK_SYSROOT) -gcc-toolchain $(NDK_VER)/prebuilt/$(NDK_HOST) -fpic \
  	-target armv7-none-linux-androideabi -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fno-exceptions -fno-rtti \
	-I$(NDK_HOME)/sources/android/native_app_glue \
	-I$(NDK_HOME)/sources/cxx-stl/gnu-libstdc++/4.9/include \
	-I$(NDK_HOME)/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a/include \
	-I$(NDK_HOME)/sources/cxx-stl/gnu-libstdc++/4.9/include/backward \
	-I$(NDK_SYSROOT)usr/include \
	-DANDROID
  XLDFLAGS = $(TARGET_CFLAGS) -Wl,-soname,libamulet.so -shared \
 	$(NDK_HOME)/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a/libgnustl_static.a -lgcc \
	-no-canonical-prefixes -Wl,--fix-cortex-a8 \
	-L$(NDK_SYSROOT)/usr/lib -llog -landroid -lEGL -lGLESv2 -lOpenSLES -llog -lc -lm 
  LUA_CFLAGS += -DLUA_USE_POSIX
  ANDROID = 1
else ifeq ($(TARGET_PLATFORM),html)
  CC = emcc
  CPP = em++
  AR = emar
  LINK = em++
  XLDFLAGS = --memory-init-file 0 -s NO_EXIT_RUNTIME=1 -s ALLOW_MEMORY_GROWTH=1 $(EMSCRIPTEN_EXPORTS_OPT) $(EMSCRIPTEN_LIBS_OPTS)
  #XLDFLAGS += -s DEMANGLE_SUPPORT=1
  XCFLAGS += -Wno-unneeded-internal-declaration $(EMSCRIPTEN_EXPORTS_OPT)
  EXE_OUT_OPT = -o$(SPACE)
  OBJ_OUT_OPT = -o$(SPACE)
  ifdef IS_WINDOWS
    CC = cmd //C emcc.bat
    CPP = cmd //C em++.bat
    AR = cmd //C emar.bat
    LINK = cmd //C em++.bat
  endif
else ifeq ($(TARGET_PLATFORM),msvc32)
  VC_CL = cl.exe
  VC_CL_PATH = $(shell which $(VC_CL))
  VC_CL_DIR = $(shell dirname "$(VC_CL_PATH)")
  VC_LINK = "$(VC_CL_DIR)/link.exe"
  VC_LIB = "$(VC_CL_DIR)/lib.exe"
  EXE_EXT = .exe
  ALIB_EXT = .lib
  OBJ_EXT = .obj
  OBJ_OUT_OPT = -Fo
  EXE_OUT_OPT = /OUT:
  CC = $(VC_CL)
  CPP = $(VC_CL)
  LINK = $(VC_LINK)
  AR = $(VC_LIB)
  AR_OPTS = -nologo
  AR_OUT_OPT = -OUT:
  XCFLAGS = -DLUA_COMPAT_ALL -WX 
  XLDFLAGS = -NODEFAULTLIB:msvcrt.lib \
	$(BUILD_LIB_DIR)/SDL2.lib
  TARGET_CFLAGS = -nologo -EHsc -fp:fast
  WINDOWS = 1
  WINDOWS_SUBSYSTEM_OPT = -SUBSYSTEM:WINDOWS
  CONSOLE_SUBSYSTEM_OPT = -SUBSYSTEM:CONSOLE
  SDL_PREBUILT_SUBDIR=win32
  C99_OPT =
else ifeq ($(TARGET_PLATFORM),mingw32)
  EXE_EXT = .exe
  CC = i686-w64-mingw32-gcc
  CPP = i686-w64-mingw32-g++
  LINK = $(CPP)
  AR = i686-w64-mingw32-ar
  XLDFLAGS = -static $(BUILD_LIB_DIR)/SDL2.lib 
  XCFLAGS = -Wall -Werror -fno-strict-aliasing
  LUAJIT_FLAGS += HOST_CC="gcc -m32" CROSS=i686-w64-mingw32- TARGET_SYS=Windows
  WINDOWS = 1
  WINDOWS_SUBSYSTEM_OPT = -mwindows
  CONSOLE_SUBSYSTEM_OPT =
  SDL_PREBUILT_SUBDIR=win32
else ifeq ($(TARGET_PLATFORM),mingw64)
  EXE_EXT = .exe
  CC = x86_64-w64-mingw32-gcc
  CPP = x86_64-w64-mingw32-g++
  LINK = $(CPP)
  AR = x86_64-w64-mingw32-ar
  XLDFLAGS = -static $(BUILD_LIB_DIR)/SDL2.lib
  XCFLAGS = -Wall -Werror -fno-strict-aliasing
  LUAJIT_FLAGS += HOST_CC="gcc -m64" CROSS=x86_64-w64-mingw32- TARGET_SYS=Windows
  WINDOWS = 1
  WINDOWS_SUBSYSTEM_OPT = -mwindows
  CONSOLE_SUBSYSTEM_OPT =
else ifeq ($(TARGET_PLATFORM),linux32)
  TARGET_CFLAGS += -m32
  LDFLAGS += -m32
  LUA_CFLAGS += -DLUA_USE_POSIX -DLUA_USE_DLOPEN
  LUAJIT_FLAGS += CC="gcc -m32"
else ifeq ($(TARGET_PLATFORM),linux64)
  LUA_CFLAGS += -DLUA_USE_POSIX -DLUA_USE_DLOPEN
endif

# Adjust flags for grade
ifeq ($(GRADE),debug)
  ifeq ($(TARGET_PLATFORM),html)
    GRADE_CFLAGS = -O1 -profiling
    GRADE_LDFLAGS = -profiling
    LUA_CFLAGS += -DLUA_USE_APICHECK
  else ifeq ($(TARGET_PLATFORM),msvc32)
    GRADE_CFLAGS = -MTd -Zi
    GRADE_LDFLAGS = -DEBUG
    LUA_CFLAGS += -DLUA_USE_APICHECK
    LUAJIT_FLAGS += CFLAGS="-DLUA_USE_APICHECK -g" LDFLAGS=-g
  else
    GRADE_CFLAGS = -g -O1
    GRADE_LDFLAGS = -g 
    LUA_CFLAGS += -DLUA_USE_APICHECK
    LUAJIT_FLAGS += CFLAGS="-DLUA_USE_APICHECK -g" LDFLAGS=-g
  endif
else
  ifeq ($(TARGET_PLATFORM),html)
    EM_PROFILING =
    #EM_PROFILING = --profiling
    GRADE_CFLAGS = -O2 $(EM_PROFILING) -DNDEBUG
    GRADE_LDFLAGS = -O2 $(EM_PROFILING) 
  else ifeq ($(TARGET_PLATFORM),msvc32)
    GRADE_CFLAGS = -Ox -DNDEBUG
    GRADE_LDFLAGS =
  else ifeq ($(TARGET_PLATFORM),osx)
    GRADE_CFLAGS = -O3 -DNDEBUG
    GRADE_LDFLAGS =
  else ifeq ($(TARGET_PLATFORM),ios32)
    GRADE_CFLAGS = -O3 -DNDEBUG
    GRADE_LDFLAGS =
  else ifeq ($(TARGET_PLATFORM),ios64)
    GRADE_CFLAGS = -O3 -DNDEBUG
    GRADE_LDFLAGS =
  else ifeq ($(TARGET_PLATFORM),android)
    GRADE_CFLAGS = -O3 -DNDEBUG
    GRADE_LDFLAGS =
  else
    GRADE_CFLAGS = -O3 -DNDEBUG
    GRADE_LDFLAGS = -s
  endif
endif

COMMON_CFLAGS := $(TARGET_CFLAGS) $(GRADE_CFLAGS) $(CFLAGS)

SDL_PREBUILT_DIR = $(THIRD_PARTY_DIR)/SDL2-prebuilt/$(SDL_PREBUILT_SUBDIR)
ANGLE_WIN_PREBUILT_DIR = $(THIRD_PARTY_DIR)/angle-win-prebuilt
