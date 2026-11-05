# SPDX-FileCopyrightText: 2026 LichtFeld Studio Authors
#
# SPDX-License-Identifier: GPL-3.0-or-later

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO haasn/libplacebo
    REF "v${VERSION}"
    SHA512 875df54b6ad6c2a4fc0fcbfeaeeb9f143c683b516b77248386377759868be5e39d73981ea3c329432650570b55146c929e0839e31d4d38096cffca7f1f3a2162
    HEAD_REF master
)

vcpkg_download_distfile(
    JINJA_ARCHIVE
    URLS "https://files.pythonhosted.org/packages/source/J/Jinja2/jinja2-3.1.5.tar.gz"
    FILENAME "jinja2-3.1.5.tar.gz"
    SHA512 c9667793d56f6b5536b5ec63ce2f99ff4ee128be410aa6670868f773663ab38c82ab4774cae5d95d85289cb0460f994d5fb556814b7e8c1fa3179fe9db85b2e5
)
vcpkg_extract_source_archive(JINJA_SOURCE ARCHIVE "${JINJA_ARCHIVE}")

vcpkg_download_distfile(
    MARKUPSAFE_ARCHIVE
    URLS "https://files.pythonhosted.org/packages/source/M/MarkupSafe/MarkupSafe-2.1.5.tar.gz"
    FILENAME "MarkupSafe-2.1.5.tar.gz"
    SHA512 d044e5cc5b95a4623ee5723b20757f5c531d279cf296c09b6348633e722514ab3b6ce17bb33044a2c0bc376a928929e735e5d168581023fc0952d4392762283e
)
vcpkg_extract_source_archive(MARKUPSAFE_SOURCE ARCHIVE "${MARKUPSAFE_ARCHIVE}")

file(COPY "${JINJA_SOURCE}/src/"
     DESTINATION "${SOURCE_PATH}/3rdparty/jinja/src")
file(COPY "${MARKUPSAFE_SOURCE}/src/"
     DESTINATION "${SOURCE_PATH}/3rdparty/markupsafe/src")

# libplacebo uses GNU C extensions; use clang-cl only for this Windows port.
if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    set(_lfs_clang_cl "")
    find_program(_lfs_clang_cl_found NAMES clang-cl clang-cl.exe HINTS "C:/Users/dabin/development/llvm/bin" "$ENV{LLVM_ROOT}/bin")
    if(NOT _lfs_clang_cl_found AND EXISTS "C:/Users/dabin/development/llvm/bin/clang-cl.exe")
        set(_lfs_clang_cl_found "C:/Users/dabin/development/llvm/bin/clang-cl.exe")
    endif()
    if(_lfs_clang_cl_found)
        set(_lfs_clang_cl "${_lfs_clang_cl_found}")
    endif()
    if(NOT _lfs_clang_cl AND DEFINED ENV{VCINSTALLDIR} AND NOT "$ENV{VCINSTALLDIR}" STREQUAL "")
        file(TO_CMAKE_PATH "$ENV{VCINSTALLDIR}" _lfs_vc_installation)
        set(_lfs_clang_cl_candidate "${_lfs_vc_installation}/Tools/Llvm/x64/bin/clang-cl.exe")
        if(EXISTS "${_lfs_clang_cl_candidate}")
            set(_lfs_clang_cl "${_lfs_clang_cl_candidate}")
        endif()
    endif()
    if(NOT _lfs_clang_cl)
        set(_lfs_vs_where "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer/vswhere.exe")
        if(EXISTS "${_lfs_vs_where}")
            vcpkg_execute_required_process(
                COMMAND "${_lfs_vs_where}" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Llvm.Clang -property installationPath
                WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}"
                LOGNAME "vswhere-clang-cl"
                OUTPUT_VARIABLE _lfs_vs_latest
            )
            string(STRIP "${_lfs_vs_latest}" _lfs_vs_latest)
            set(_lfs_clang_cl_candidate "${_lfs_vs_latest}/VC/Tools/Llvm/x64/bin/clang-cl.exe")
            if(EXISTS "${_lfs_clang_cl_candidate}")
                set(_lfs_clang_cl "${_lfs_clang_cl_candidate}")
            endif()
        endif()
    endif()

    if(NOT _lfs_clang_cl)
        message(FATAL_ERROR
            "Building libplacebo on Windows requires clang-cl (LLVM C/C++ compiler). "
            "Please install LLVM or the 'C++ Clang Compiler for Windows' component in Visual Studio.")
    endif()

    # Override only Meson's C/C++ compiler; keep vcpkg's MSVC settings.
    get_filename_component(_lfs_clang_dir "${_lfs_clang_cl}" DIRECTORY)
    find_program(_lfs_lld_link NAMES lld-link lld-link.exe HINTS "${_lfs_clang_dir}" "C:/Users/dabin/development/llvm/bin" "C:/Users/dabin/development/tools/lld-bin")
    if(_lfs_lld_link)
        set(_lfs_lld_dir "${CURRENT_BUILDTREES_DIR}/lld-bin")
        file(MAKE_DIRECTORY "${_lfs_lld_dir}")
        if(NOT EXISTS "${_lfs_lld_dir}/lld-link.exe")
            file(CREATE_LINK "${_lfs_lld_link}" "${_lfs_lld_dir}/lld-link.exe" COPY_ON_ERROR)
        endif()
        vcpkg_add_to_path(PREPEND "${_lfs_lld_dir}")
    endif()

    set(_lfs_clang_native_file "${CURRENT_BUILDTREES_DIR}/clang-cl-${TARGET_TRIPLET}.ini")
    set(_lfs_native_content
        "[binaries]\n"
        "c = ['${_lfs_clang_cl}']\n"
        "cpp = ['${_lfs_clang_cl}']\n")
    if(_lfs_lld_link)
        string(APPEND _lfs_native_content
            "c_ld = ['${_lfs_lld_link}']\n"
            "cpp_ld = ['${_lfs_lld_link}']\n")
    endif()
    file(WRITE "${_lfs_clang_native_file}" "${_lfs_native_content}")
    set(VCPKG_MESON_NATIVE_FILE_DEBUG "${_lfs_clang_native_file}")
    set(VCPKG_MESON_NATIVE_FILE_RELEASE "${_lfs_clang_native_file}")
endif()

vcpkg_check_features(OUT_FEATURE_FLAGS FEATURE_FLAGS
    FEATURES
        d3d11       d3d11
        glslang     glslang
        lcms        lcms2
        shaderc     shaderc
        vulkan      vulkan
        xxhash      xxhash
)

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_FLAGS}
        -Ddemos=false
        -Dtests=false
        -Dbench=false
        -Dfuzz=false
)

vcpkg_install_meson()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
