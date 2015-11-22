#!/usr/bin/env bash

set -e
# Increase max_allowed_packet so it's easier to revert features.
mysql -e "SET GLOBAL max_allowed_packet=128*1024*1024;"

# Install Compass
gem update --system
gem install sass --version "=3.4.12"
gem install compass --version "=1.0.3"

# Run the make script.
echo "::Running build"
bash tmp/scripts/build.sh $PROJECT $INSTALL_PROFILE/build-$PROJECT.make $BUILD_TEST

# Install Drush integration
echo "::Installing Drush integration"
cp $INSTALL_PROFILE/tmp/travis_scripts/$PROJECT.aliases.drushrc.php $HOME/.drush/$PROJECT.aliases.drushrc.php

# Remove files that we don't want on prod.
cd ${BUILD_DEST}
rm -rf profiles/${PROJECT}/tmp
rm profiles/${PROJECT}/rebuild.sh
rm profiles/${PROJECT}/.gitignore
rm profiles/${PROJECT}/.travis.yml
rm profiles/${PROJECT}/README.md
rm profiles/${PROJECT}/*.make
rm .gitignore
rm README.txt
rm LICENSE.txt
rm example.gitignore

# Copy the built site over to the deploy folder.
cd $HOME/build/
mkdir $PROJECT_deploy
cd $BUILD_TEST
shopt -s dotglob
cp -R * $BUILD_DEPLOY

# Copy local settings file for Travis env to the test folder.
cp $INSTALL_PROFILE/tmp/travis_scripts/settings.local.php $BUILD_TEST/sites/default/settings.local.php

echo  ":: Installing $PROJECT"
cd $BUILD_TEST
drush si $PROJECT --db-url=mysql://root:@localhost:3306/${PROJECT} --site-name="$PROJECT" --account-pass="admin" -y