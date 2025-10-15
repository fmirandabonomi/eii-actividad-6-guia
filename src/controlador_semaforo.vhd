library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlador_semaforo is
    generic (
        constant Npre      : integer;
        constant Cpre      : unsigned(Npre-1 downto 0);
        constant NTimer    : integer;
        constant TVerde    : integer;
        constant TAmarillo : integer;
        constant TPeaton   : integer);
    port (
        clk : in std_logic;
        nreset : in std_logic;
        
        solicitudPeatonA : in std_logic;
        solicitudPeatonB : in std_logic;
        solicitudEmergenciaA : in std_logic;
        solicitudEmergenciaB : in std_logic;
        confirmacionPeatonA : out std_logic;
        confirmacionPeatonB : out std_logic;
        confirmacionEmergenciaA : out std_logic;
        confirmacionEmergenciaB : out std_logic;

        transitoA : out std_logic_vector (1 downto 0);
        peatonA : out std_logic;
        transitoB : out std_logic_vector (1 downto 0);
        peatonB : out std_logic);
end controlador_semaforo;

architecture arch of controlador_semaforo is
begin

end arch ; -- arch