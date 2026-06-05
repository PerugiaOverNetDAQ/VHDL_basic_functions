--!@file parametric_ram_dp.vhd
--!@brief Parametric true dual-port RAM. Both ports can be used for read or write.
--!@details The intended usage in the SMA architecture is:
--!         - writer gets one port when the arbiter grants write access;
--!         - SMA gets both ports when it needs two parallel reads;
--!         - downstream reader gets both ports when granted.
--!         Read latency is one clock from the registered address phase.
--!@author Luca Russo
--!@date 05/06/2026
--!@version 1.0

library ieee;
use ieee.std_logic_1164.all;

library altera;
use altera.all;

library altera_mf;
use altera_mf.all;

entity parametric_ram_dp is
    generic (
        pWIDTH       : natural := 32;   --! Word width
        pDEPTH       : natural := 128;  --! Number of words
        pUSEDW_WIDTH : natural := 7;    --! ceil(log2(pDEPTH))
        pFORCE_MLAB  : natural := 1     --! 1 = force MLAB, 0 = AUTO
    );
    port (
        iCLK : in std_logic;

        -- Port A
        iData_A : in  std_logic_vector(pWIDTH-1 downto 0);
        iAddr_A : in  std_logic_vector(pUSEDW_WIDTH-1 downto 0);
        iWE_A   : in  std_logic;
        iRE_A   : in  std_logic;
        oData_A : out std_logic_vector(pWIDTH-1 downto 0);

        -- Port B
        iData_B : in  std_logic_vector(pWIDTH-1 downto 0);
        iAddr_B : in  std_logic_vector(pUSEDW_WIDTH-1 downto 0);
        iWE_B   : in  std_logic;
        iRE_B   : in  std_logic;
        oData_B : out std_logic_vector(pWIDTH-1 downto 0)
    );
end entity parametric_ram_dp;

architecture SYN of parametric_ram_dp is

    function f_ram_block_type(force_mlab : natural) return string is
    begin
        if force_mlab = 1 then
            return "MLAB";
        else
            return "AUTO";
        end if;
    end function;

    component altsyncram
        generic (
            address_aclr_a  : string := "UNUSED";
            address_aclr_b  : string := "NONE";
            address_reg_b   : string := "CLOCK0";

            byte_size       : natural := 8;

            byteena_aclr_a  : string := "UNUSED";
            byteena_aclr_b  : string := "NONE";
            byteena_reg_b   : string := "CLOCK0";

            clock_enable_core_a   : string := "USE_INPUT_CLKEN";
            clock_enable_core_b   : string := "USE_INPUT_CLKEN";
            clock_enable_input_a  : string := "NORMAL";
            clock_enable_input_b  : string := "NORMAL";
            clock_enable_output_a : string := "NORMAL";
            clock_enable_output_b : string := "NORMAL";

            intended_device_family : string := "unused";

            enable_ecc       : string := "FALSE";
            implement_in_les : string := "OFF";

            indata_aclr_a : string := "UNUSED";
            indata_aclr_b : string := "NONE";
            indata_reg_b  : string := "CLOCK0";

            init_file        : string := "UNUSED";
            init_file_layout : string := "PORT_A";

            maximum_depth : natural := 0;

            numwords_a : natural := 0;
            numwords_b : natural := 0;

            operation_mode : string := "BIDIR_DUAL_PORT";

            outdata_aclr_a : string := "NONE";
            outdata_aclr_b : string := "NONE";
            outdata_reg_a  : string := "UNREGISTERED";
            outdata_reg_b  : string := "UNREGISTERED";

            power_up_uninitialized : string := "FALSE";

            ram_block_type : string := "AUTO";

            rdcontrol_aclr_b : string := "NONE";
            rdcontrol_reg_b  : string := "CLOCK0";

            read_during_write_mode_mixed_ports : string := "DONT_CARE";
            read_during_write_mode_port_a      : string := "NEW_DATA_NO_NBE_READ";
            read_during_write_mode_port_b      : string := "NEW_DATA_NO_NBE_READ";

            width_a : natural;
            width_b : natural := 1;

            width_byteena_a : natural := 1;
            width_byteena_b : natural := 1;

            widthad_a : natural;
            widthad_b : natural := 1;

            wrcontrol_aclr_a : string := "UNUSED";
            wrcontrol_aclr_b : string := "NONE";
            wrcontrol_wraddress_reg_b : string := "CLOCK0";

            lpm_hint : string := "UNUSED";
            lpm_type : string := "altsyncram"
        );
        port (
            aclr0 : in std_logic := '0';
            aclr1 : in std_logic := '0';

            address_a : in std_logic_vector(widthad_a-1 downto 0);
            address_b : in std_logic_vector(widthad_b-1 downto 0) := (others => '1');

            addressstall_a : in std_logic := '0';
            addressstall_b : in std_logic := '0';

            byteena_a : in std_logic_vector(width_byteena_a-1 downto 0) := (others => '1');
            byteena_b : in std_logic_vector(width_byteena_b-1 downto 0) := (others => '1');

            clock0 : in std_logic := '1';
            clock1 : in std_logic := '1';

            clocken0 : in std_logic := '1';
            clocken1 : in std_logic := '1';
            clocken2 : in std_logic := '1';
            clocken3 : in std_logic := '1';

            data_a : in std_logic_vector(width_a-1 downto 0) := (others => '1');
            data_b : in std_logic_vector(width_b-1 downto 0) := (others => '1');

            eccstatus : out std_logic_vector(2 downto 0);

            q_a : out std_logic_vector(width_a-1 downto 0);
            q_b : out std_logic_vector(width_b-1 downto 0);

            rden_a : in std_logic := '1';
            rden_b : in std_logic := '1';

            wren_a : in std_logic := '0';
            wren_b : in std_logic := '0'
        );
    end component;

begin

    u_altsyncram : altsyncram
        generic map (
            address_aclr_b => "NONE",
            address_reg_b  => "CLOCK0",

            clock_enable_input_a  => "BYPASS",
            clock_enable_input_b  => "BYPASS",
            clock_enable_output_a => "BYPASS",
            clock_enable_output_b => "BYPASS",

            intended_device_family => "Cyclone V",
            lpm_type        => "altsyncram",
            operation_mode  => "BIDIR_DUAL_PORT",

            numwords_a      => pDEPTH,
            widthad_a       => pUSEDW_WIDTH,
            width_a         => pWIDTH,
            width_byteena_a => 1,

            numwords_b      => pDEPTH,
            widthad_b       => pUSEDW_WIDTH,
            width_b         => pWIDTH,
            width_byteena_b => 1,

            outdata_aclr_a  => "NONE",
            outdata_aclr_b  => "NONE",
            outdata_reg_a   => "UNREGISTERED",
            outdata_reg_b   => "UNREGISTERED",

            ram_block_type => f_ram_block_type(pFORCE_MLAB),

            power_up_uninitialized => "FALSE",
            read_during_write_mode_mixed_ports => "DONT_CARE"
        )
        port map (
            clock0    => iCLK,
            eccstatus => open,

            address_a => iAddr_A,
            data_a    => iData_A,
            wren_a    => iWE_A,
            rden_a    => iRE_A,
            q_a       => oData_A,

            address_b => iAddr_B,
            data_b    => iData_B,
            wren_b    => iWE_B,
            rden_b    => iRE_B,
            q_b       => oData_B
        );

end architecture SYN;
