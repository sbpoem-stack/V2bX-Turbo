package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var (
	version  = "Turbo-v1.0.0"
	codename = "V2bX-Turbo"
	intro    = "High-Performance Multi-Core Proxy Backend with BBR Extreme Acceleration"
)

var versionCommand = cobra.Command{
	Use:   "version",
	Short: "Print version info",
	Run: func(_ *cobra.Command, _ []string) {
		showVersion()
	},
}

func init() {
	command.AddCommand(&versionCommand)
}

func showVersion() {
	fmt.Println(` 
  ██╗   ██╗██████╗ ██████╗ ██╗  ██╗    ████████╗██╗   ██╗██████╗ ██████╗  ██████╗ 
  ██║   ██║╚════██╗██╔══██╗╚██╗██╔╝    ╚══██╔══╝██║   ██║██╔══██╗██╔══██╗██╔═══██╗
  ██║   ██║ █████╔╝██████╔╝ ╚███╔╝        ██║   ██║   ██║██████╔╝██████╔╝██║   ██║
  ╚██╗ ██╔╝██╔═══╝ ██╔══██╗ ██╔██╗        ██║   ██║   ██║██╔══██╗██╔══██╗██║   ██║
   ╚████╔╝ ███████╗██████╔╝██╔╝ ██╗       ██║   ╚██████╔╝██║  ██║██████╔╝╚██████╔╝
    ╚═══╝  ╚══════╝╚═════╝ ╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝ 
    `)
	fmt.Printf("%s %s (%s) \n", codename, version, intro)
	fmt.Println("🚀 Powered by sbpoem-stack & BBR Turbo Optimization")
}
