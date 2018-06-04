#!/bin/bash

set -euo pipefail

component=${1}

hab pkg build "components/${component}"

# TODO (CM): Push to Builder in a release channel
# TODO (CM): pass a release channel in as an argument / environment variable
# TODO (CM): pass an auth token in environment
# TODO (CM): Keep the HART as an artifact in Buildkite?
#            Might be a good way to ensure that we've got the hab
#            version we just built
# TODO (CM): pass in an origin key and import it


# In Travis, we had to have logic for pushing depending on whether
# we're doing a release build or not. Since we can construct the
# pipeline however we want here, we can have simpler scripts