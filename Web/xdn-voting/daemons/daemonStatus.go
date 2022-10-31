package daemons

import (
	"encoding/json"
	"io"
	"strconv"
	"strings"
	"xdn-voting/coind"
	"xdn-voting/models"
	"xdn-voting/utils"
)

var daemonStatus models.DaemonStatus

func DaemonStatus() {
	blkReqXDN, errNet := utils.GETAny("https://xdn-explorer.com/api/getblockcount")
	if errNet != nil {
		utils.WrapErrorLog(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
		return
	}

	bodyXDN, _ := io.ReadAll(blkReqXDN.Body)
	blockhashXDN, _ := strconv.Atoi(string(bodyXDN))
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}(blkReqXDN.Body)

	daemonStatus.BlockCount = blockhashXDN

	blk, errBlock := coind.WrapDaemon(utils.DaemonWallet, 1, "getblockcount")
	if errBlock != nil {
		utils.WrapErrorLog(errBlock.Error())
		return
	}
	blockCountWallet, errBlock := strconv.Atoi(strings.Trim(string(blk), "\""))
	if errBlock != nil {
		utils.WrapErrorLog(errBlock.Error())
		return
	}
	blkStake, errBlock := coind.WrapDaemon(utils.DaemonStakeWallet, 1, "getblockcount")
	if errBlock != nil {
		utils.WrapErrorLog(errBlock.Error())
		return
	}
	blockCountStakeWallet, errBlock := strconv.Atoi(strings.Trim(string(blkStake), "\""))
	if errBlock != nil {
		utils.WrapErrorLog(errBlock.Error())
		return
	}

	if blockCountWallet == blockhashXDN {
		daemonStatus.Block = true
	} else {
		daemonStatus.Block = false
	}

	if blockCountStakeWallet == blockhashXDN {
		daemonStatus.BlockStake = true
	} else {
		daemonStatus.BlockStake = false
	}
	stake, errBlock := coind.WrapDaemon(utils.DaemonStakeWallet, 1, "getstakinginfo")
	if errBlock != nil {
		utils.WrapErrorLog(errBlock.Error())
		return
	}
	var stakeInfo models.StakingInfo
	_ = json.Unmarshal(stake, &stakeInfo)

	daemonStatus.WalletStake = stakeInfo.Staking

	summary, errNet := utils.GETAny("https://xdn-explorer.com/ext/summary")
	if errNet != nil {
		utils.WrapErrorLog(errNet.ErrorMessage() + " " + strconv.Itoa(errNet.StatusCode()))
		return
	}

	bodySummary, _ := io.ReadAll(summary.Body)
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			utils.WrapErrorLog(err.Error())
		}
	}(blkReqXDN.Body)

	var sum models.Summary
	err := json.Unmarshal(bodySummary, &sum)
	if err != nil {
		utils.WrapErrorLog(err.Error())
		return
	}
	daemonStatus.MasternodeCount = sum.Data[0].Masternodecount
	daemonStatus.Difficulty = sum.Data[0].Difficulty
	daemonStatus.HashRate = sum.Data[0].Hashrate
	daemonStatus.CoinSupply = sum.Data[0].Supply

	info, errBlock := coind.WrapDaemon(utils.DaemonWallet, 1, "getinfo")
	if errBlock != nil {
		utils.WrapErrorLog(errBlock.Error())
		return
	}

	var inf models.GetInfo

	err = json.Unmarshal(info, &inf)
	daemonStatus.Version = inf.Version
}

func GetDaemonStatus() models.DaemonStatus {
	return daemonStatus
}
