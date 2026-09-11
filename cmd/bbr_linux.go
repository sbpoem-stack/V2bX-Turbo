package cmd

import (
	"fmt"
	"os"

	"github.com/InazumaV/V2bX/common/exec"
	"github.com/spf13/cobra"
)

var bbrCommand = cobra.Command{
	Use:   "bbr",
	Short: "Optimize Linux TCP/UDP network stack with BBR Turbo",
	Run: func(_ *cobra.Command, _ []string) {
		fmt.Println(Ok("正在启动 V2bX-Turbo 极速网络调优引擎 (BBR Turbo Extreme)..."))
		// 如果本地已有脚本则直接执行，否则从用户仓库远程获取
		if _, err := os.Stat("/usr/local/V2bX/bbr_turbo.sh"); err == nil {
			exec.RunCommandStd("bash", "/usr/local/V2bX/bbr_turbo.sh")
		} else {
			exec.RunCommandStd("bash", "-c", "curl -fsSL https://raw.githubusercontent.com/sbpoem-stack/bbr-turbo/main/bbr_turbo.sh | bash")
		}
	},
}

func init() {
	command.AddCommand(&bbrCommand)
}
