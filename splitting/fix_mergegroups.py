#!/usr/bin/env python3
# vim:set tabstop=4 shiftwidth=4 expandtab smarttab

from json import loads, dumps
from os import listdir
from os.path import join

from lib import read_symbols, sort_groups, scrapelabels

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('groups', default="groups.json", type=argparse.FileType('r'))
parser.add_argument('-p', '--prefix', default="", type=str)
parser.add_argument('-r', '--refs', default="references.json", type=argparse.FileType('r'))
parser.add_argument('-o', '--out', default="groups.merged.json", type=argparse.FileType('w'))
args = parser.parse_args()

syms = read_symbols(open(join(args.prefix, "pokecrystal.sym")))
groups = loads(args.groups.read())
refs = loads(args.refs.read())

def mergegroup(labels):
    finalgroups = {}
    removegroups = []
    for label in labels:
        if syms[label][0] not in finalgroups:
            finalgroups[syms[label][0]] = []
        finalgroup = finalgroups[syms[label][0]]

        if label in finalgroup:
            continue
        for index, group in enumerate(groups):
            if label in group:
                finalgroup += group
                removegroups.append(index)
                break
        else:
            print("Not found:", label)
            exit(1)

    removegroups.sort(reverse=True)
    for index in removegroups:
        del groups[index]

    for group in finalgroups:
        groups.append(finalgroups[group])

maps = []
for line in open(join(args.prefix, "data", "maps", "attributes.asm")):
    if line.startswith("\tmap_attributes "):
        maps.append(line.strip().split(" ")[1].strip().split(",")[0].strip())

# These things are not worth splitting, because literally every label is
#   standalone, and they're all related.
mergegroup(scrapelabels(join(args.prefix, "gfx", "tilesets.asm")))
mergegroup(scrapelabels(join(args.prefix, "gfx", "battle_anims.asm")))
mergegroup(scrapelabels(join(args.prefix, "gfx", "sprites.asm")))
mergegroup(scrapelabels(join(args.prefix, "gfx", "font.asm")))
mergegroup(scrapelabels(join(args.prefix, "gfx", "emotes.asm")))
mergegroup(scrapelabels(join(args.prefix, "gfx", "pics.asm")))
mergegroup(["%s_MapAttributes" % x for x in maps])
mergegroup(scrapelabels(join(args.prefix, "data", "maps", "blocks.asm")))
for file in listdir(join(args.prefix, "data", "phone", "text")):
    mergegroup(scrapelabels(join(args.prefix, "data", "phone", "text", file)))
for file in ["common_%d.asm" % x for x in range(1, 4)] + ["std_text.asm"]:
    mergegroup(scrapelabels(join(args.prefix, "data", "text", file)))
mergegroup(scrapelabels(join(args.prefix, "data", "battle_tower", "trainer_text.asm")))
mergegroup(scrapelabels(join(args.prefix, "data", "battle_tower", "unknown.asm")))

# All of the phone scripts belong in at least the same bank,
#  there's no use splitting them beyond file boundaries.
callers = []
for file in listdir(join(args.prefix, "engine", "phone", "scripts")):
    # Except for the callers, which I can't really split in any meaningful way.
    # PhoneScript_HangupText_Male/Female are referenced by nearly everything.
    if file.endswith("_gossip.asm") or file.startswith("hangups") or file.startswith("reminders") or file in ["bike_shop.asm", "generic_caller.asm"]:
        callers += scrapelabels(join(args.prefix, "engine", "phone", "scripts", file))
        continue

    # And the family strings used by TiffanysFamilyMemebers...
    if file == "generic_callee.asm":
        labels = scrapelabels(join(args.prefix, "engine", "phone", "scripts", "generic_callee.asm"))
        family = ["GrandmaString", "GrandpaString", "MomString", "DadString", "SisterString", "BrotherString"]
        labels = [x for x in labels if x not in family]
        mergegroup(family)
        mergegroup(labels)
        continue

    mergegroup(scrapelabels(join(args.prefix, "engine", "phone", "scripts", file)))
mergegroup(callers)

# A lot of songs abuse fallthrough into non-local labels
#   (because whoever extracted them didn't bother fixing them afterwards, 
#   and there's really not a lot of sensible names you can give them anyway)
# These were already split up in a sensible manner, so there's no point to doing that again:
for file in listdir(join(args.prefix, "audio", "music")):
    mergegroup(scrapelabels(join(args.prefix, "audio", "music", file)))

# A lot of specials are defined in the same area, despite only being referenced through BANK()
mergegroup(scrapelabels(join(args.prefix, "engine", "events", "specials.asm")))

# All StdScripts are in the same area, despite only being referenced through BANK()
# As such, it makes little sense to split them.
mergegroup(scrapelabels(join(args.prefix, "engine", "events", "std_scripts.asm")))

# These utility functions are all related to objects
mergegroup(scrapelabels(join(args.prefix, "engine", "overworld", "player_object.asm")))

# This function is only ever used by another one in the same bank, it doesn't need a separate section
mergegroup(["HDMATransfer_FillBGMap0WithBlack", "ReanchorBGMap_NoOAMUpdate"])

# DefaultMart doesn't need its own section despite being referenced through BANK()
mergegroup(["DefaultMart", "Marts"])

# BattleText_0x8188e is unused but belongs in BattleTexts
mergegroup(["BattleText_0x8188e", "BattleText_LinkErrorBattleCanceled"])

# These functions are empty and unused but _damn_
mergegroup(["Function823c6", "Function823c7", "Function82391"])

# The Egg assets _can_ all be in a different bank but there's really no reason to
mergegroup(["EggAnimation", "CelebiAnimation"])
mergegroup(["EggAnimationIdle", "CelebiAnimationIdle"])
mergegroup(["EggBitmasks", "CelebiBitmasks"])
mergegroup(["EggFrames", "CelebiFrames"])

args.out.write(dumps(sort_groups(groups, True), indent=4))
