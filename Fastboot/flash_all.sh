fastboot $* getvar product 2>&1 | grep -E  "^product: *popsicle"
if [ $? -ne 0  ] ; then echo "Missmatching image and device"; exit 1; fi

#check anti_version
if [ -e $(dirname $0)/images/anti_version.txt ]; then
CURRENT_ANTI_VER=`cat $(dirname $0)/images/anti_version.txt`
fi
if [ -z "$CURRENT_ANTI_VER" ]; then CURRENT_ANTI_VER=0; fi
ver=`fastboot $* getvar anti 2>&1 | grep -oP "anti: \K[0-9]+"`
if [ -z "$ver" ]; then ver=0; fi
if [ $ver -gt $CURRENT_ANTI_VER ]; then echo "Current device antirollback version is greater than this pakcage"; exit 1; fi

fastboot $* getvar crc 2>&1 | grep "^crc: 1"
if [ $? -eq 0 ]; then
fastboot $* flash crclist       `dirname $0`/images/crclist.txt
if [ $? -ne 0 ] ; then echo "Flash crclist error"; exit 1; fi
fastboot $* flash sparsecrclist `dirname $0`/images/sparsecrclist.txt
if [ $? -ne 0 ] ; then echo "Flash sparsecrclist error"; exit 1; fi
fi

fastboot $* erase boot_ab
if [ $? -ne 0 ] ; then echo "Erase boot error"; exit 1; fi
fastboot $* flash abl_ab `dirname $0`/images/abl.elf
if [ $? -ne 0 ] ; then echo "Flash abl error"; exit 1; fi
fastboot $* flash xbl_ab `dirname $0`/images/xbl_sc.elf
if [ $? -ne 0 ] ; then echo "Flash xbl error"; exit 1; fi
fastboot $* flash xbl_config_ab `dirname $0`/images/xbl_config.elf
if [ $? -ne 0 ] ; then echo "Flash xbl_config error"; exit 1; fi
fastboot $* flash multiimgqti_ab `dirname $0`/images/multi_image_qti.mbn
if [ $? -ne 0 ] ; then echo "Flash multiimgqti error"; exit 1; fi
fastboot $* flash multiimgoem_ab `dirname $0`/images/multi_image.mbn
if [ $? -ne 0 ] ; then echo "Flash multiimgoem error"; exit 1; fi
fastboot $* flash tme_seq_patch_ab `dirname $0`/images/sequencer_ram.elf
if [ $? -ne 0 ] ; then echo "Flash tme_seq_patch error"; exit 1; fi
fastboot $* flash tme_fw_ab `dirname $0`/images/signed_firmware_soc_view.elf
if [ $? -ne 0 ] ; then echo "Flash tme_fw error"; exit 1; fi
fastboot $* flash tme_config_ab `dirname $0`/images/tme_config.elf
if [ $? -ne 0 ] ; then echo "Flash tme_config error"; exit 1; fi
fastboot $* flash xbl_ac_config_ab `dirname $0`/images/xbl_ac_config.mbn
if [ $? -ne 0 ] ; then echo "Flash xbl_ac_config error"; exit 1; fi
fastboot $* flash ddr `dirname $0`/images/zeros_5sectors.bin
if [ $? -ne 0 ] ; then echo "Flash ddr error"; exit 1; fi
fastboot $* flash uefi_ab `dirname $0`/images/uefi.elf
if [ $? -ne 0 ] ; then echo "Flash uefi error"; exit 1; fi
fastboot $* flash aop_ab `dirname $0`/images/aop.mbn
if [ $? -ne 0 ] ; then echo "Flash aop error"; exit 1; fi
fastboot $* flash aop_config_ab `dirname $0`/images/aop_devcfg.mbn
if [ $? -ne 0 ] ; then echo "Flash aop_config error"; exit 1; fi
fastboot $* flash tz_ab `dirname $0`/images/tz.mbn
if [ $? -ne 0 ] ; then echo "Flash tz error"; exit 1; fi
fastboot $* flash hyp_ab `dirname $0`/images/hypvmperformance.mbn
if [ $? -ne 0 ] ; then echo "Flash hyp error"; exit 1; fi
fastboot $* flash modem_ab `dirname $0`/images/NON-HLOS.bin
if [ $? -ne 0 ] ; then echo "Flash modem error"; exit 1; fi
fastboot $* flash modemfirmware_ab `dirname $0`/images/MODEM-FW.bin
if [ $? -ne 0 ] ; then echo "Flash modem firmware error"; exit 1; fi
fastboot $* flash bluetooth_ab `dirname $0`/images/BTFM.bin
if [ $? -ne 0 ] ; then echo "Flash bluetooth error"; exit 1; fi
fastboot $* flash dsp_ab `dirname $0`/images/dspso.bin
if [ $? -ne 0 ] ; then echo "Flash dsp error"; exit 1; fi
fastboot $* flash keymaster_ab `dirname $0`/images/keymint.mbn
if [ $? -ne 0 ] ; then echo "Flash keymaster error"; exit 1; fi
fastboot $* flash spuservice_ab `dirname $0`/images/spu_service.mbn
if [ $? -ne 0 ] ; then echo "Flash spuservice error"; exit 1; fi
fastboot $* flash devcfg_ab `dirname $0`/images/devcfg.mbn
if [ $? -ne 0 ] ; then echo "Flash devcfg error"; exit 1; fi
fastboot $* flash qupfw_ab `dirname $0`/images/qupv3fw.elf
if [ $? -ne 0 ] ; then echo "Flash qupfw error"; exit 1; fi
fastboot $* flash uefisecapp_ab `dirname $0`/images/uefi_sec.mbn
if [ $? -ne 0 ] ; then echo "Flash uefisecapp error"; exit 1; fi
fastboot $* erase imagefv_ab
if [ $? -ne 0 ] ; then echo "Erase imagesfv error"; exit 1; fi
fastboot $* flash imagefv_ab `dirname $0`/images/imagefv.elf
if [ $? -ne 0 ] ; then echo "Flash imagefv error"; exit 1; fi
fastboot $* flash shrm_ab `dirname $0`/images/shrm.elf
if [ $? -ne 0 ] ; then echo "Flash shrm error"; exit 1; fi
fastboot $* flash cpucp_ab `dirname $0`/images/cpucp.elf
if [ $? -ne 0 ] ; then echo "Flash cpucp error"; exit 1; fi
fastboot $* flash idmanager_ab `dirname $0`/images/idmanager.mbn
if [ $? -ne 0 ] ; then echo "Flash idmamager error"; exit 1; fi
fastboot $* flash featenabler_ab `dirname $0`/images/featenabler.mbn
if [ $? -ne 0 ] ; then echo "Flash featenabler error"; exit 1; fi
fastboot $* flash xbl_ramdump_ab `dirname $0`/images/XblRamdump.elf
if [ $? -ne 0 ] ; then echo "Flash xbl_ramdump error"; exit 1; fi
fastboot $* flash cpucp_dtb_ab `dirname $0`/images/cpucp_dtbs.elf
if [ $? -ne 0 ] ; then echo "Flash cpucp_dtb error"; exit 1; fi
fastboot $* flash soccp_ab `dirname $0`/images/soccp.bin
if [ $? -ne 0 ] ; then echo "Flash soccp error"; exit 1; fi
fastboot $* flash soccp_debug_ab `dirname $0`/images/sdi.mbn
if [ $? -ne 0 ] ; then echo "Flash soccp_debug error"; exit 1; fi
fastboot $* flash soccp_dcd_ab `dirname $0`/images/dcd.mbn
if [ $? -ne 0 ] ; then echo "Flash soccp_dcd error"; exit 1; fi
fastboot $* flash pdp_ab `dirname $0`/images/pdp.elf
if [ $? -ne 0 ] ; then echo "Flash pdp error"; exit 1; fi
fastboot $* flash pdp_cdb_ab `dirname $0`/images/pdp_cdb.elf
if [ $? -ne 0 ] ; then echo "Flash pdp_cdb error"; exit 1; fi
fastboot $* flash xbl_sc_test_mode `dirname $0`/images/xbl_sc_test_mode.bin
if [ $? -ne 0 ] ; then echo "Flash xbl_sc_test_mode error"; exit 1; fi
fastboot $* flash tz_ac_config_ab `dirname $0`/images/tz_ac_config.mbn
if [ $? -ne 0 ] ; then echo "Flash tz_ac_config error"; exit 1; fi
fastboot $* flash hyp_ac_config_ab `dirname $0`/images/hyp_ac_config.mbn
if [ $? -ne 0 ] ; then echo "Flash hyp_ac_config error"; exit 1; fi
fastboot $* flash dcp_ab `dirname $0`/images/dcp.bin
if [ $? -ne 0 ] ; then echo "Flash dcp error"; exit 1; fi
fastboot $* flash tz_qti_config_ab `dirname $0`/images/tz_qti_config.mbn
if [ $? -ne 0 ] ; then echo "Flash tz_qti_config error"; exit 1; fi
fastboot $* flash secretkeeper_ab `dirname $0`/images/secretkeeper.mbn
if [ $? -ne 0 ] ; then echo "Flash secretkeeper error"; exit 1; fi
fastboot $* flash toolsfv `dirname $0`/images/tools.fv
if [ $? -ne 0 ] ; then echo "Flash toolsfv error"; exit 1; fi
fastboot $* flash logfs `dirname $0`/images/logfs_ufs_8mb.bin
if [ $? -ne 0 ] ; then echo "Flash logfs error"; exit 1; fi
fastboot $* flash storsec `dirname $0`/images/storsec.mbn
if [ $? -ne 0 ] ; then echo "Flash storsec error"; exit 1; fi
fastboot $* flash super `dirname $0`/images/super.img
if [ $? -ne 0 ] ; then echo "Flash super error"; exit 1; fi
fastboot $* erase metadata
if [ $? -ne 0 ] ; then echo "Erase metadata error"; exit 1; fi
fastboot $* flash metadata `dirname $0`/images/metadata.img
if [ $? -ne 0 ] ; then echo "Flash metadata error"; exit 1; fi
fastboot $* flash userdata `dirname $0`/images/userdata.img
if [ $? -ne 0 ] ; then echo "Flash userdata error"; exit 1; fi
fastboot $* flash rescue `dirname $0`/images/rescue.img
if [ $? -ne 0 ] ; then echo "Flash rescue error"; exit 1; fi
fastboot $* flash misc `dirname $0`/images/misc.img
if [ $? -ne 0 ] ; then echo "Flash misc error"; exit 1; fi
fastboot $* flash vbmeta_ab `dirname $0`/images/vbmeta.img
if [ $? -ne 0 ] ; then echo "Flash vbmeta error"; exit 1; fi
fastboot $* flash vbmeta_system_ab `dirname $0`/images/vbmeta_system.img
if [ $? -ne 0 ] ; then echo "Flash vbmeta_system error"; exit 1; fi
fastboot $* flash vm-bootsys_ab `dirname $0`/images/vm-bootsys.img
if [ $? -ne 0 ] ; then echo "Flash vm-bootsys error"; exit 1; fi
fastboot $* flash qtvm_dtbo_ab `dirname $0`/images/qtvm-dtbo.img
if [ $? -ne 0 ] ; then echo "Flash qtvm_dtbo error"; exit 1; fi
fastboot $* flash recovery_ab `dirname $0`/images/recovery.img
if [ $? -ne 0 ] ; then echo "Flash recovery error"; exit 1; fi
fastboot $* flash pvmfw_ab `dirname $0`/images/pvmfw.img
if [ $? -ne 0 ] ; then echo "Flash pvmfw error"; exit 1; fi
fastboot $* flash countrycode_ab `dirname $0`/images/countrycode.img
if [ $? -ne 0 ] ; then echo "Flash countrycode error"; exit 1; fi
fastboot $* flash vendor_boot_ab `dirname $0`/images/vendor_boot.img
if [ $? -ne 0 ] ; then echo "Flash vendor_boot error"; exit 1; fi
fastboot $* flash init_boot_ab `dirname $0`/images/init_boot.img
if [ $? -ne 0 ] ; then echo "Flash init_boot error"; exit 1; fi
fastboot $* flash dtbo_ab `dirname $0`/images/dtbo.img
if [ $? -ne 0 ] ; then echo "Flash dtbo error"; exit 1; fi
fastboot $* flash boot_ab `dirname $0`/images/boot.img
if [ $? -ne 0 ] ; then echo "Flash boot error"; exit 1; fi
fastboot $* set_active a
if [ $? -ne 0 ] ; then echo "set_active a error"; exit 1; fi
fastboot $* reboot
if [ $? -ne 0 ] ; then echo "Reboot error"; exit 1; fi
