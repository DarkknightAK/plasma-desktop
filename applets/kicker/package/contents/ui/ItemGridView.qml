/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0
import org.kde.draganddrop 2.0

FocusScope {
    id: itemGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    property bool dragEnabled: true
    property bool dropEnabled: false
    property bool showLabels: true

    property int pressX: -1
    property int pressY: -1

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias count: gridView.count
    property alias model: gridView.model

    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight

    property alias horizontalScrollBarPolicy: scrollArea.horizontalScrollBarPolicy
    property alias verticalScrollBarPolicy: scrollArea.verticalScrollBarPolicy

    onDropEnabledChanged: {
        if (!dropEnabled && "dropPlaceHolderIndex" in model) {
            model.dropPlaceHolderIndex = -1;
        }
    }

    onFocusChanged: {
        if (!focus && !root.keyEventProxy.activeFocus) {
            currentIndex = -1;
        }
    }

    function currentRow() {
        if (currentIndex == -1) {
            return -1;
        }

        return Math.floor(currentIndex / Math.floor(width / cellWidth));
    }

    function currentCol() {
        if (currentIndex == -1) {
            return -1;
        }

        return currentIndex - (currentRow() * Math.floor(width / cellWidth));
    }

    function lastRow() {
        var columns = Math.floor(width / cellWidth);
        return Math.ceil(count / columns) - 1;
    }

    function tryActivate(row, col) {
        if (count) {
            var columns = Math.floor(width / cellWidth);
            var rows = Math.ceil(count / columns);
            row = Math.min(row, rows - 1);
            col = Math.min(col, columns - 1);
            currentIndex = Math.min(row ? ((Math.max(1, row) * columns) + col)
                : col,
                count - 1);

            focus = true;
        }
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    DropArea {
        id: dropArea

        anchors.fill: parent

        onDragMove: {
            if (!dropEnabled || gridView.animating || !kicker.dragSource) {
                return;
            }

            var x = Math.max(0, event.x - (width % cellWidth));
            var cPos = mapToItem(gridView.contentItem, x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item) {
                if (kicker.dragSource.parent == gridView.contentItem) {
                    if (item != kicker.dragSource) {
                        item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
                    }
                } else if (kicker.dragSource.view.model.favoritesModel == model
                    && !model.isFavorite(kicker.dragSource.favoriteId)) {
                    var hasPlaceholder = (model.dropPlaceholderIndex != -1);

                    model.dropPlaceholderIndex = item.itemIndex;

                    if (!hasPlaceholder) {
                        gridView.currentIndex = (item.itemIndex - 1);
                    }
                }
            } else if (kicker.dragSource.parent != gridView.contentItem
                && kicker.dragSource.view.model.favoritesModel == model
                && !model.isFavorite(kicker.dragSource.favoriteId)) {
                    var hasPlaceholder = (model.dropPlaceholderIndex != -1);

                    model.dropPlaceholderIndex = hasPlaceholder ? model.count - 1 : model.count;

                    if (!hasPlaceholder) {
                        gridView.currentIndex = (model.count - 1);
                    }
            } else {
                model.dropPlaceholderIndex = -1;
                gridView.currentIndex = -1;
            }
        }

        onDragLeave: {
            if ("dropPlaceholderIndex" in model) {
                model.dropPlaceholderIndex = -1;
                gridView.currentIndex = -1;
            }
        }

        onDrop: {
            if (kicker.dragSource && kicker.dragSource.parent != gridView.contentItem && kicker.dragSource.view.model.favoritesModel == model) {
                model.addFavorite(kicker.dragSource.favoriteId, model.dropPlaceholderIndex);
                gridView.currentIndex = -1;
            }
        }

        MouseEventListener {
            anchors.fill: parent

            hoverEnabled: true

            onPressed: {
                pressX = mouse.x;
                pressY = mouse.y;
            }

            onReleased: {
                pressX = -1;
                pressY = -1;
            }

            onClicked: {
                var cPos = mapToItem(gridView.contentItem, mouse.x, mouse.y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    root.toggle();
                }
            }

            onPositionChanged: {
                var cPos = mapToItem(gridView.contentItem, mouse.x, mouse.y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    gridView.currentIndex = -1;
                } else {
                    gridView.currentIndex = item.itemIndex;
                    itemGrid.focus = (currentIndex != -1)

                    if (dragEnabled && pressX != -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                        kicker.dragSource = item;
                        dragHelper.startDrag(kicker, item.url, item.icon);
                        pressX = -1;
                        pressY = -1;
                    }
                }
            }

            onContainsMouseChanged: {
                if (!containsMouse) {
                    gridView.currentIndex = -1;
                    pressX = -1;
                    pressY = -1;
                }
            }

            Timer {
                id: resetAnimationDurationTimer

                interval: 120
                repeat: false

                onTriggered: {
                    gridView.animationDuration = interval - 20;
                }
            }

            PlasmaExtras.ScrollArea {
                id: scrollArea

                anchors.fill: parent

                focus: true

                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                GridView {
                    id: gridView

                    property bool animating: false
                    property int animationDuration: dropEnabled ? resetAnimationDurationTimer.interval : 0

                    focus: true

                    currentIndex: -1

                    move: Transition {
                        enabled: itemGrid.dropEnabled

                        SequentialAnimation {
                            PropertyAction { target: gridView; property: "animating"; value: true }

                            NumberAnimation {
                                duration: gridView.animationDuration
                                properties: "x, y"
                                easing.type: Easing.OutQuad
                            }

                            PropertyAction { target: gridView; property: "animating"; value: false }
                        }
                    }

                    moveDisplaced: Transition {
                        enabled: itemGrid.dropEnabled

                        SequentialAnimation {
                            PropertyAction { target: gridView; property: "animating"; value: true }

                            NumberAnimation {
                                duration: gridView.animationDuration
                                properties: "x, y"
                                easing.type: Easing.OutQuad
                            }

                            PropertyAction { target: gridView; property: "animating"; value: false }
                        }
                    }

                    keyNavigationWraps: false
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: ItemGridDelegate {
                        showLabel: showLabels
                    }

                    highlight: Item {
                        property bool isDropPlaceHolder: "dropPlaceholderIndex" in model && currentIndex == model.dropPlaceholderIndex

                        PlasmaComponents.Highlight {
                            visible: gridView.currentItem && !isDropPlaceHolder

                            anchors.fill: parent
                        }

                        PlasmaCore.FrameSvgItem {
                            visible: gridView.currentItem && isDropPlaceHolder

                            anchors.fill: parent

                            imagePath: "widgets/viewitem"
                            prefix: "selected"

                            opacity: 0.5

                            PlasmaCore.IconItem {
                                anchors {
                                    right: parent.right
                                    rightMargin: parent.margins.right
                                    bottom: parent.bottom
                                    bottomMargin: parent.margins.bottom
                                }

                                width: units.iconSizes.smallMedium
                                height: width

                                source: "list-add"
                                active: false
                            }
                        }
                    }

                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0

                    onCurrentIndexChanged: {
                        if (currentIndex != -1) {
                            focus = true;
                        }
                    }

                    onCountChanged: {
                        animationDuration = 0;
                        resetAnimationDurationTimer.start();
                    }

                    onModelChanged: {
                        currentIndex = -1;
                    }

                    Keys.onLeftPressed: {
                        if (currentCol() != 0) {
                            event.accepted = true;
                            moveCurrentIndexLeft();
                        } else {
                            itemGrid.keyNavLeft();
                        }
                    }

                    Keys.onRightPressed: {
                        var columns = Math.floor(width / cellWidth);

                        if (currentCol() != columns - 1 && currentIndex != count -1) {
                            event.accepted = true;
                            moveCurrentIndexRight();
                        } else {
                            itemGrid.keyNavRight();
                        }
                    }

                    Keys.onUpPressed: {
                        if (currentRow() != 0) {
                            event.accepted = true;
                            moveCurrentIndexUp();
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        } else {
                            itemGrid.keyNavUp();
                        }
                    }

                    Keys.onDownPressed: {
                        if (currentRow() < itemGrid.lastRow()) {
                            // Fix moveCurrentIndexDown()'s lack of proper spatial nav down
                            // into partial columns.
                            event.accepted = true;
                            var columns = Math.floor(width / cellWidth);
                            var newIndex = currentIndex + columns;
                            currentIndex = Math.min(newIndex, count - 1);
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        } else {
                            itemGrid.keyNavDown();
                        }
                    }
                }
            }
        }
    }
}
