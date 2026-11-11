#!/usr/bin/env bash
set -euo pipefail

defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 25
defaults write -g AppleShowAllExtensions -bool true
defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 61
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0

defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder NewWindowTarget -string PfDe
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

defaults write com.apple.screencapture target -string clipboard
defaults write com.apple.screencapture target-screenshot -string clipboard
defaults write com.apple.screencapture target-screenrecording -string file

defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

killall Dock Finder SystemUIServer || true
