#!/usr/bin/env python

import os
import re
import subprocess
import sys
import json
import logging
import logging.config
import time
import multiprocessing
import traceback
import itertools
import fnmatch
from functools import reduce


def InitLogging():
  DEFAULT_LOGGING_CONFIG = {
      'version': 1,
      'disable_existing_loggers': False,
      'formatters': {
          'standard': {
              'format':
                  '%(asctime)s - %(filename)s - %(levelname)-8s: %(message)s',
              'datefmt': '%Y-%m-%d %H:%M:%S',
          },
      },
      'handlers': {
          'default': {
              'class': 'logging.StreamHandler',
              'formatter': 'standard',
              'level': 'INFO',
          },
      },
      'loggers': {
          '': {
              'handlers': ['default'],
              'propagate': True,
              'level': 'NOTSET',
          }
      }
  }
  logging.config.dictConfig(DEFAULT_LOGGING_CONFIG)

logger = logging.getLogger(__name__)

def parse_flash_script(path, script, skip):
    def search_image_name(stream):
        file = re.match(r'(.*?images\b\S)([^/]+)$', stream)
        if file is None:
            return None
        if len(file.groups()) < 2:
            return None # pragma: no cover
        return file.group(2).strip()
    basename = script[0]
    suffix = script[1]
    full_name = '{}/{}.{}'.format(path, basename, suffix)
    out = {}
    with open(full_name , "r") as f:
        for l in f:
            words = l.strip().split()
            if len(words) < 3:
                continue
            if words[0] != "fastboot" or words[2] != "flash":
                continue
            try:
                partition = re.sub(r'_ab$', '', words[3].strip())
                if partition in skip:
                    continue
                file = list(filter(None, map(search_image_name, words[4:])))[0]
                out[partition] = file
            except Exception as e: # pragma: no cover
                logging.error('Check flash scripts error! There is wrong file name for <{}> in <{}>.'.format(partition, '{}.{}'.format(basename, suffix)))
    return out


def parse_flash_scripts(path, skip):
    scripts = [ "flash_all", "flash_all_lock", "flash_all_except_storage" ]
    suffix = [ "sh", "bat"]
    return dict(map(lambda x: ( "{}.{}".format(x[0], x[1]), parse_flash_script(path, x, skip)), itertools.product(scripts , suffix)))

def split_partition_line(stream):
    matched = re.match(r'^\s*<program .*filename="(.*?)".*?label="(.*?)"', stream)
    if matched is None:
        return None
    if len(matched.groups()) < 2:
        return None # pragma: no cover
    return { re.sub(r'_a$', '', matched.group(2)) : matched.group(1) }  # for match the fastboot label, need strip '_a' of label, such as "abl_a" to "abl"

def parse_rawprogram(f_raw):
    out = {}
    with open(f_raw, "r") as f:
        for l in f:
            item = split_partition_line(l)
            if item is None:
                continue
            out.update(item)
    return out

def search_rawprogram_files(directory):
    matched = []
    for root, dirs, files in os.walk(directory):
        for filename in fnmatch.filter(files, "rawprogram*.xml"):
            matched.append(os.path.join(root, filename))
    return matched

def parse_rawprograms(path):
    combine = {}
    for k,v in map(lambda x: ( "{}".format(x), parse_rawprogram(x)), search_rawprogram_files(path)):
        merge_name = "{}/merged_partition.xml".format(os.path.dirname(k))
        combine.setdefault(merge_name, {})
        combine[merge_name].update(v)
    return combine

def get_dict_difference(this, that):
    all_keys = set(this.keys()) | set(that.keys())
    def compare_key(key):
        if key not in this:
            return key
        elif key not in that:
            return key
        elif this[key] != that[key]:
            return key
        else:
            return None
    differences = list(filter(lambda x: x is not None, map(compare_key, all_keys)))
    return differences

def compare_some_scripts(scripts, base, ignore=[]):
    # find the base script
    template = next(filter(lambda x: x.find(base) >= 0, scripts.keys()), None)
    if template is None:
        raise ValueError("Wrong base file name: <{}>".format(base)) # pragma: no cover
    # compare all scripts
    for file, detail in scripts.items():
        if file == template:
            continue
        for key in get_dict_difference(scripts[template], detail):
            if key in ignore:
                continue
            raise ValueError("Inconsistencies of <{}> were discovered when comparing the flash scripts between <{}> and <{}>".format(key, template, file))
    return scripts[template]

def check_partition(root, region):
    is_miui = region not in [ "factory", "native" ]
    is_factory = region  == "factory"

    # Setup <partition> -> <image> map from edl scripts(rawprogram*.xml)
    edl = parse_rawprograms(root)

    # Setup <partition> -> <image> map from fastboot scripts(flash_all*.sh and flash_all*.bat)
    defalut_skip_label = [ "crclist", "sparsecrclist", "partition:0", "partition:1", "partition:2", "partition:3", "partition:4", "partition:5" ]
    special_skip_label = [ "modem", "modemfirmware", "apdp", "apdpb" ]
    fastboot = parse_flash_scripts(root, defalut_skip_label + special_skip_label )

    # Check the consistency between fastboot flashing scripts.
    fastboot = compare_some_scripts(fastboot, "flash_all.bat", [ "userdata", "metadata"])

    # Check the consistency between edl flashing scripts.
    edl = compare_some_scripts(edl, next(iter(edl.keys())), [ 'opcust' ]) if len(edl) > 1  else next(iter(edl.values()))

    # Check if the image in fastboot scripts(flash_all_xx.sh and flash_all_xx.bat) is present in edl scripts (rawprogram*.xml)
    for fp,ff in fastboot.items():
        ef = edl.get(fp)
        if fp == 'rescue':
            if is_factory:
                assert  ef != "", "The partition of <rescue> must be flashed in edl mode for factory version."
            else:
                assert  ef == "", "The partition of <rescue> must be not flashed in edl mode for non-factory version."
            continue
        assert  ef == ff, "Found a different image between edl script and fastboot script for <{}> partition.".format(fp)

    # In edl mode, need to flashed images for factory version and keep not be flashed images for miui version in nv partition
    flashed = True if is_factory else False
    for nv in ["modemst1", "modemst2", "fsg", "persist", "vm-persist", "secdata", "apdp", "apdpb"]:
        if nv not in edl.keys():
            raise ValueError("Not found <{}> partition(nv) in rawprogram.xml.".format(nv)) # pragma: no cover
        assert bool(edl[nv]) == flashed, "Must flashed(or not be flashed) the <{}> partition for corresponding version(factory or miui).".format(nv)

    # In edl mode, must flashed some partition for all version
    for partition in [ "ddr" ]:
        if partition not in edl.keys():
            raise ValueError("Not found <{}> partition in rawprogram.xml.".format(partition)) # pragma: no cover
        assert bool(edl[partition]) == True, "Must flashed the <{}> partition for all version.".format(partition)

def get_region_from_rom(root):
    # get region from misc.txt in image directory
    version_file = os.path.join(root, "misc.txt")
    if os.path.exists(version_file) is False:
        return None
    region = None
    profile = None
    with open(version_file, "r") as f:
        for line in f:
            _region = re.match(r'^\s*region\s*=\s*(\w*)\s*$', line)
            _profile = re.match(r'^\s*profile\s*=\s*(.*)s*$', line)
            if _region is None and _profile is None:
                continue
            if _region is not None:
                region = _region.group(1).strip()
                continue
            if _profile is not None:
                profile = re.search(r'\b(factory|native)\b', _profile.group(1))
    if region is not None and region != "":
        return region
    if profile is not None:
        return profile.group(0)
    return None # pragma: no cover



def main(): # pragma: no cover
    InitLogging()
    root = os.path.dirname(__file__)
    region = get_region_from_rom(root)
    if region is None:
        logging.warning("Cannot found the region from misc.txt.")
        sys.exit(0)
    check_partition(root, region)
    logging.info("Check partition successed.")

if __name__ == '__main__':
    main() # pragma: no cover
