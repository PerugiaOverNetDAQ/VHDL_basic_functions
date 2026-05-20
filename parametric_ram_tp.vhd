--!@file parametric_ram_tp.vhd
--!@brief Parametric RAM block, two port and MLAB can be forced.
--!@author Luca Russo, luca.russo@cern.ch, luca.russo912@gmail.com
--!@date 05/05/2020
--!@version 0.1 - 05/05/2026 
library ieee;
use ieee.std_logic_1164.all;

library altera;
use altera.all;

library altera_mf;
use altera_mf.all;

entity parametric_ram_tp is
    generic (
        pWIDTH       : natural := 32;   --! Word width
        pDEPTH       : natural := 128;  --! RAM number of words
        pUSEDW_WIDTH : natural := 7;    --! ceil(log2(pDEPTH))
        pFORCE_MLAB  : natural := 1     --! 1 = force MLAB, 0 = AUTO
    );
    port (
        iCLK     : in  std_logic;

        iData    : in  std_logic_vector(pWIDTH-1 downto 0);
        iRd_Addr : in  std_logic_vector(pUSEDW_WIDTH-1 downto 0);
        iWr_Addr : in  std_logic_vector(pUSEDW_WIDTH-1 downto 0);
        iWr_En   : in  std_logic;

        oData    : out std_logic_vector(pWIDTH-1 downto 0)
    );
end entity parametric_ram_tp;


architecture SYN of parametric_ram_tp is

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
            address_reg_b   : string := "CLOCK1";

            byte_size       : natural := 8;

            byteena_aclr_a  : string := "UNUSED";
            byteena_aclr_b  : string := "NONE";
            byteena_reg_b   : string := "CLOCK1";

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
            indata_reg_b  : string := "CLOCK1";

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
            rdcontrol_reg_b  : string := "CLOCK1";

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
            wrcontrol_wraddress_reg_b : string := "CLOCK1";

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
            clock_enable_input_a   => "BYPASS",
            clock_enable_input_b   => "BYPASS",
            clock_enable_output_b  => "BYPASS",
            intended_device_family => "Cyclone V",
            lpm_type        => "altsyncram",
            operation_mode  => "DUAL_PORT",
            numwords_a      => pDEPTH,
            widthad_a       => pUSEDW_WIDTH,
            width_a         => pWIDTH,
            width_byteena_a => 1,
            numwords_b      => pDEPTH,
            widthad_b       => pUSEDW_WIDTH,
            width_b         => pWIDTH,
            width_byteena_b => 1,
            outdata_aclr_b  => "NONE",
            outdata_reg_b   => "UNREGISTERED", --Riduco la latenza di 1CLK

            -- RAM implementation
            ram_block_type => f_ram_block_type(pFORCE_MLAB),

            power_up_uninitialized => "FALSE",
            read_during_write_mode_mixed_ports => "DONT_CARE"
        )
        port map (
            clock0    => iCLK,
            address_a => iWr_Addr,
            data_a    => iData,
            wren_a    => iWr_En,
            address_b => iRd_Addr,
            q_b       => oData
        );

end architecture SYN;
