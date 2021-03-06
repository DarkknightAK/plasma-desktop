find_package (ECM 0.0.8 REQUIRED NO_MODULE)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

find_package (Qt5 REQUIRED NO_MODULE COMPONENTS Widgets Qml X11Extras)
find_package (KF5I18n         ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5Config       ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5CoreAddons   ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5GlobalAccel  ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5GuiAddons    ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5KIO          ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5Activities   ${KF5_DEP_VERSION} CONFIG REQUIRED)
find_package (KF5WindowSystem ${KF5_DEP_VERSION} CONFIG REQUIRED)

find_package (X11)
set_package_properties (
   X11 PROPERTIES DESCRIPTION "X11 libraries"
   URL "http://www.x.org"
   TYPE REQUIRED
   )

set (
   activityswitcher_imports_LIB_SRCS
   activityswitcherextensionplugin.cpp
   switcherbackend.cpp
   sortedactivitiesmodel.cpp
   )

add_library (activityswitcherextensionplugin SHARED ${activityswitcher_imports_LIB_SRCS})
add_definitions(-DTRANSLATION_DOMAIN=\"plasmaactivitymanager\")

target_link_libraries (
   activityswitcherextensionplugin

   Qt5::Core
   Qt5::Qml
   Qt5::Widgets
   Qt5::X11Extras

   KF5::I18n
   KF5::Activities
   KF5::ConfigCore
   KF5::CoreAddons
   KF5::GlobalAccel
   KF5::GuiAddons
   KF5::KIOCore
   KF5::KIOWidgets
   KF5::WindowSystem
   ${X11_X11_LIB}
   )

## install

install (TARGETS activityswitcherextensionplugin
         DESTINATION ${QML_INSTALL_DIR}/org/kde/plasma/activityswitcher)
install (FILES qmldir
         DESTINATION ${QML_INSTALL_DIR}/org/kde/plasma/activityswitcher)

