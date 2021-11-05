#!/bin/bash
if [[ ! -z "$(git --global user.name)" ]]; then
  echo "You dont have a git name configured, you know what to do: \n git --global user.name lovelyName"
fi
if [[ ! -z "$(git --global user.email)" ]]; then
  echo "You dont have a git email configured, you know what to do: \n git --global user.email lovelyEmail"
fi

sudo rm -- $0