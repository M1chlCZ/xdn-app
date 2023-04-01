package fn

import (
	"fmt"
	"os/exec"
	"strconv"
	"xdn-masternode/database"
	"xdn-masternode/grpcClient"
	"xdn-masternode/grpcModels"
	"xdn-masternode/utils"
)

func RemoveMN(folder string) error {
	if folder == "" {
		return utils.ReturnError("folder is empty")
	}
	utils.ReportMessage("Stopping service")
	if err := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user stop %s", folder)).Run(); err != nil {
		utils.ReportMessage("Error stopping service")
		return utils.ReturnError(err.Error())
	}

	utils.ReportMessage("Disabling service")
	if err := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user disable %s", folder)).Run(); err != nil {
		utils.ReportMessage("Error disabling service")
		return utils.ReturnError(err.Error())
	}

	utils.ReportMessage("Removing service")
	if err := exec.Command("bash", "-c", fmt.Sprintf("rm %s/.config/systemd/user/%s.service", utils.GetHomeDir(), folder)).Run(); err != nil {
		utils.ReportMessage("Error removing service")
		return utils.ReturnError(err.Error())
	}

	utils.ReportMessage("Reloading service")
	if err := exec.Command("bash", "-c", fmt.Sprintf("systemctl --user daemon-reload")).Run(); err != nil {
		utils.ReportMessage("Error reloading service")
		return utils.ReturnError(err.Error())
	}

	utils.ReportMessage("Removing folder")
	if err := exec.Command("bash", "-c", fmt.Sprintf("rm -rf %s/%s", utils.GetHomeDir(), folder)).Run(); err != nil {
		utils.ReportMessage("Error removing folder")
		return utils.ReturnError(err.Error())
	}

	dm, err := database.GetDaemonFolder(folder)
	if err != nil {
		return utils.ReturnError("Can't get folder from db")
	}
	nodeID := dm.NodeID

	utils.ReportMessage(fmt.Sprintf("Removing node %s", folder))
	tx := &grpcModels.RemoveMasternodeRequest{
		NodeID: uint32(nodeID),
	}

	nodes, err := grpcClient.RemoveMasternode(tx)
	if err != nil {
		return utils.ReturnError(err.Error())
	}

	if nodes.Code != 200 {
		return utils.ReturnError(strconv.Itoa(int(nodes.Code)) + " Node delete fail")
	}

	_, err = database.RemoveDaemon(nodeID)
	if err != nil {
		return err
	}
	return nil
}
