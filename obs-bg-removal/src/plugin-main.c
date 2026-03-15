#include <obs-module.h>
#include "plugin-support.h"

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE(PLUGIN_NAME, "en-US")

extern struct obs_source_info bg_removal_filter;

bool obs_module_load(void)
{
	obs_register_source(&bg_removal_filter);
	obs_log(LOG_INFO, "BG Removal plugin loaded (version %s)", PLUGIN_VERSION);
	return true;
}

void obs_module_unload(void)
{
	obs_log(LOG_INFO, "BG Removal plugin unloaded");
}
