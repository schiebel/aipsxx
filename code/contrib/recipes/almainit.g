#initialization file for ALMA TSTs
#
#This includes several scripts which initializes the tools being
#evaluated
#
ok:=dl.note('Initializing suite of tools for ALMA TSTs');
include 'mirfiller.g';
include 'almati2ms.g';
include 'vlafiller.g';
include 'ms.g';
#include 'flagger.g';
include 'autoflag.g';
include 'msplot.g';
include 'calibrater.g';
include 'viewer.g';
include 'imager.g';
include 'image.g';
#include 'imagepol.g';

