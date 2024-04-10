library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART

entity pong_graph_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(3 downto 0);
        video_on: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    ); 
end pong_graph_st;

architecture sq_ball_arch of pong_graph_st is
-- Signal used to control speed of ball and how
-- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;

-- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);

-- screen dimensions
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;

-- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;
    
-- paddle left, right, top, bottom and height left &
-- right are constant. top & bottom are signals to
-- allow movement. bar_y_t driven by reg below.
    
    signal bar_x_l, bar_x_r: unsigned( 9 downto 0); -- signal for bar movement right and left
    signal bar_y_t, bar_y_b: unsigned(9 downto 0);
    constant BAR_Y_SIZE: integer := 72;
    constant BAR_X_SIZE: integer := 10;

-- reg to track top boundary (x position is fixed)
    signal bar_x_reg, bar_x_next: unsigned(9 downto 0);----- reg to track x position 
    signal bar_y_reg, bar_y_next: unsigned(9 downto 0);

-- bar moving velocity when a button is pressed
-- the amount the bar is moved.
    constant BAR_V: integer:= 4;
    constant BAR_X: integer:= 3;

-- square ball -- ball left, right, top and bottom
-- all vary. Left and top driven by registers below.
    constant BALL_SIZE: integer := 12;
    --alien 1
    signal ball1_x_l, ball1_x_r: unsigned(9 downto 0);
    signal ball1_y_t, ball1_y_b: unsigned(9 downto 0);
    --alien 2
    signal ball2_x_l, ball2_x_r: unsigned(9 downto 0);
    signal ball2_y_t, ball2_y_b: unsigned(9 downto 0);
    --alien 3
    signal ball3_x_l, ball3_x_r: unsigned(9 downto 0);
    signal ball3_y_t, ball3_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal ball1_x_reg, ball1_x_next: unsigned(9 downto 0);
    signal ball1_y_reg, ball1_y_next: unsigned(9 downto 0);

    signal ball2_x_reg, ball2_x_next: unsigned(9 downto 0);
    signal ball2_y_reg, ball2_y_next: unsigned(9 downto 0);

    signal ball3_x_reg, ball3_x_next: unsigned(9 downto 0);
    signal ball3_y_reg, ball3_y_next: unsigned(9 downto 0);

-- reg to track ball speed
    signal x1_delta_reg, x1_delta_next: unsigned(9 downto 0);
    signal y1_delta_reg, y1_delta_next: unsigned(9 downto 0);

    signal x2_delta_reg, x2_delta_next: unsigned(9 downto 0);
    signal y2_delta_reg, y2_delta_next: unsigned(9 downto 0);

    signal x3_delta_reg, x3_delta_next: unsigned(9 downto 0);
    signal y3_delta_reg, y3_delta_next: unsigned(9 downto 0);

-- alien movement can be pos or neg
    constant BALL_V_P: unsigned(9 downto 0):= to_unsigned(2,10);
    constant BALL_V_N: unsigned(9 downto 0):= unsigned(to_signed(-2,10));


-- round ball image
    type rom_type is array(0 to 11) of std_logic_vector(0 to 11);
    constant BALL_ROM: rom_type:= (
        "111100000000",
        "111110000000",
        "111111000000",
        "111111100000",
        "111111111100",
        "111111111111",
        "111111111111",
        "111111111100",
        "111111100000",
        "111111000000",
        "111110000000",
        "111100000000");
    
    signal rom_addr1, rom_col1: unsigned(2 downto 0);
    signal rom_data1: std_logic_vector(11 downto 0);
    signal rom_bit1: std_logic;

    signal rom_addr2, rom_col2: unsigned(2 downto 0);
    signal rom_data2: std_logic_vector(11 downto 0);
    signal rom_bit2: std_logic;

    signal rom_addr3, rom_col3: unsigned(2 downto 0);
    signal rom_data3: std_logic_vector(11 downto 0);
    signal rom_bit3: std_logic;

-- object output signals -- new signal to indicate if
-- scan coord is within ball
    signal wall_on, bar_on, sq_ball1_on,sq_ball2_on, sq_ball3_on, rd_ball1_on, rd_ball2_on, rd_ball3_on: std_logic;
    signal wall_rgb, bar_rgb, ball_rgb: std_logic_vector(2 downto 0);
-- ====================================================

begin
    process (clk, reset)
    begin
        if (reset = '1') then
            bar_y_reg <= (others => '0');
            bar_x_reg <= (others => '0');
            ball1_x_reg <= (others => '0');---alien 1
            ball1_y_reg <= (others => '0');

            ball2_x_reg <= (others => '0');---alien 2
            ball2_y_reg <= ("0000011110");

            ball3_x_reg <= (others => '0');---alien 3
            ball3_y_reg <= ("0110010000");
            x1_delta_reg <= ("0000000100");
            y1_delta_reg <= ("0000000100");
            x2_delta_reg <= ("0000000100");
            y2_delta_reg <= ("0000000100");
            x3_delta_reg <= ("0000000100");
            y3_delta_reg <= ("0000000100");
        elsif (clk'event and clk = '1') then
            bar_y_reg <= bar_y_next;
            bar_x_reg<=bar_x_next;
            --alien1
            ball1_x_reg <= ball1_x_next;
            ball1_y_reg <= ball1_y_next;
            --alien2
            ball2_x_reg <= ball2_x_next;
            ball2_y_reg <= ball2_y_next;
            --alien3
            ball3_x_reg <= ball3_x_next;
            ball3_y_reg <= ball3_y_next;

            x1_delta_reg <= x1_delta_next;
            y1_delta_reg <= y1_delta_next;
            x2_delta_reg <= x2_delta_next;
            y2_delta_reg <= y2_delta_next;
            x3_delta_reg <= x3_delta_next;
            y3_delta_reg <= y3_delta_next;
        end if;
    end process;

    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);

    -- refr_tick: 1-clock tick asserted at start of v_sync,
    -- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else '0';

    -- wall left vertical stripe
    wall_on <= '1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else '0';
    wall_rgb <= "001"; -- blue

    -- pixel within paddle
    bar_y_t <= bar_y_reg;
    bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
    bar_x_l <= bar_x_reg;
    bar_x_r <= bar_x_reg + BAR_X_SIZE - 1;
    bar_on <= '1' when (BAR_X_L <= pix_x) and (pix_x <= BAR_X_R) and (bar_y_t <= pix_y) and (pix_y <= bar_y_b) else '0';
    bar_rgb <= "010"; -- green

    -- Process bar movement requests
    process( bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
    begin
        bar_y_next <= bar_y_reg; -- no move
        if ( refr_tick = '1' ) then
        -- if btn 1 pressed and paddle not at bottom yet
            if ( btn(1) = '1' and bar_y_b < (MAX_Y - 1 - BAR_V)) then
                bar_y_next <= bar_y_reg + BAR_V;
        -- if btn 0 pressed and bar not at top yet
            elsif ( btn(0) = '1' and bar_y_t > BAR_V) then
                bar_y_next <= bar_y_reg - BAR_V;
            end if;
        end if;
    end process;

    ---bar movement on x axis
    process(bar_x_reg,bar_x_l, bar_x_r,refr_tick, btn)
    begin      
        bar_x_next<=bar_x_reg;
        if ( refr_tick = '1' ) then
        -- if btn 1 pressed and paddle not at left yet
            if ( btn(3) = '1' and bar_x_r < (MAX_X - 1 - BAR_X)) then
                bar_x_next <= bar_X_reg + BAR_V;
        -- if btn 0 pressed and bar not at right yet
            elsif ( btn(2) = '1' and bar_x_l > BAR_X) then
                bar_x_next <= bar_x_reg - BAR_X;
            end if;
        end if;
    end process;

-- set coordinates of alien.
--alien 1
    ball1_x_l <= ball1_x_reg;
    ball1_y_t <= ball1_y_reg;
    ball1_x_r <= ball1_x_l + BALL_SIZE - 1;
    ball1_y_b <= ball1_y_t + BALL_SIZE - 1;
--alien 2
    ball2_x_l <= ball2_x_reg;
    ball2_y_t <= ball2_y_reg;
    ball2_x_r <= ball2_x_l + BALL_SIZE - 1;
    ball2_y_b <= ball2_y_t + BALL_SIZE - 1; 
--alien 3
    ball3_x_l <= ball3_x_reg;
    ball3_y_t <= ball3_y_reg;
    ball3_x_r <= ball3_x_l + BALL_SIZE - 1;
    ball3_y_b <= ball3_y_t + BALL_SIZE - 1;       

-- pixel within square ball
    sq_ball1_on <= '1' when (ball1_x_l <= pix_x) and (pix_x <= ball1_x_r) and (ball1_y_t <= pix_y) and (pix_y <= ball1_y_b) else '0';

    sq_ball2_on <= '1' when (ball2_x_l <= pix_x) and (pix_x <= ball2_x_r) and (ball2_y_t <= pix_y) and (pix_y <= ball2_y_b) else '0';

    sq_ball3_on <= '1' when (ball3_x_l <= pix_x) and (pix_x <= ball3_x_r) and (ball3_y_t <= pix_y) and (pix_y <= ball3_y_b) else '0';



-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.
-- ROM row
    rom_addr1 <= pix_y(2 downto 0) - ball1_y_t(2 downto 0);
    rom_addr2 <= pix_y(2 downto 0) - ball2_y_t(2 downto 0);
    rom_addr3 <= pix_y(2 downto 0) - ball3_y_t(2 downto 0);

-- ROM column
    rom_col1 <= pix_x(2 downto 0) - ball1_x_l(2 downto 0);
    rom_col2 <= pix_x(2 downto 0) - ball2_x_l(2 downto 0);
    rom_col3 <= pix_x(2 downto 0) - ball3_x_l(2 downto 0);

-- Get row data
    rom_data1 <= BALL_ROM(to_integer(rom_addr1));
    rom_data2 <= BALL_ROM(to_integer(rom_addr2));
    rom_data3 <= BALL_ROM(to_integer(rom_addr3));

-- Get column bit
    rom_bit1 <= rom_data1(to_integer(rom_col1));
    rom_bit2 <= rom_data2(to_integer(rom_col2));
    rom_bit3 <= rom_data3(to_integer(rom_col3));

-- Turn ball on only if within square and ROM bit is 1.
    rd_ball1_on <= '1' when (sq_ball1_on = '1') and (rom_bit1 = '1') else '0';
    rd_ball2_on <= '1' when (sq_ball2_on = '1') and (rom_bit2 = '1') else '0';
    rd_ball3_on <= '1' when (sq_ball3_on = '1') and (rom_bit3 = '1') else '0';

    ball_rgb <= "100"; -- red
-- Update the ball position 60 times per second.
    ball1_x_next <= ball1_x_reg + x1_delta_reg when refr_tick = '1' else ball1_x_reg;
    ball1_y_next <= ball1_y_reg + y1_delta_reg when refr_tick = '1' else ball1_y_reg;

    ball2_x_next <= ball2_x_reg + x2_delta_reg when refr_tick = '1' else ball2_x_reg;
    ball2_y_next <= ball2_y_reg + y2_delta_reg when refr_tick = '1' else ball2_y_reg;
    
    ball3_x_next <= ball3_x_reg + x3_delta_reg when refr_tick = '1' else ball3_x_reg;
    ball3_y_next <= ball3_y_reg + y3_delta_reg when refr_tick = '1' else ball3_y_reg;


-- Set the value of the next ball position according to the boundaries.
    process(
        x1_delta_reg, 
        y1_delta_reg,
        x2_delta_reg, 
        y2_delta_reg, 
        x3_delta_reg, 
        y3_delta_reg, 
        ball1_y_t, ball1_x_l, ball1_x_r, ball1_y_t, ball1_y_b,
        ball2_y_t, ball2_x_l, ball2_x_r, ball2_y_t, ball2_y_b,
        ball3_y_t, ball3_x_l, ball3_x_r, ball3_y_t, ball3_y_b, 
        bar_y_t, bar_y_b)
    begin
        x1_delta_next <= x1_delta_reg;
        y1_delta_next <= y1_delta_reg;
        x2_delta_next <= x2_delta_reg;
        y2_delta_next <= y2_delta_reg;
        x3_delta_next <= x3_delta_reg;
        y3_delta_next <= y3_delta_reg;
    -- ball reached top, make offset positive
        if ( ball1_y_t < 1 ) then
            y1_delta_next <= BALL_V_P;
    -- reached bottom, make negative
        elsif (ball1_y_b > (MAX_Y - 1)) then
            y1_delta_next <= BALL_V_N;
        -- reach wall, bounce back
        elsif (ball1_x_l <= WALL_X_R ) then
            x1_delta_next <= BALL_V_P;
        -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball1_x_r) and (ball1_x_r <= BAR_X_R)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball1_y_b) and (ball1_y_t <= bar_y_b)) then
                x1_delta_next <= BALL_V_N;
            end if;
        end if;

        if ( ball2_y_t < 1 ) then
            y2_delta_next <= BALL_V_P;
    -- reached bottom, make negative
        elsif (ball2_y_b > (MAX_Y - 1)) then
            y2_delta_next <= BALL_V_N;
        -- reach wall, bounce back
        elsif (ball2_x_l <= WALL_X_R ) then
            x2_delta_next <= BALL_V_P;
        -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball2_x_r) and (ball2_x_r <= BAR_X_R)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball2_y_b) and (ball2_y_t <= bar_y_b)) then
                x2_delta_next <= BALL_V_N;
            end if;
        end if;

        if ( ball3_y_t < 1 ) then
            y3_delta_next <= BALL_V_P;
    -- reached bottom, make negative
        elsif (ball3_y_b > (MAX_Y - 1)) then
            y3_delta_next <= BALL_V_N;
        -- reach wall, bounce back
        elsif (ball3_x_l <= WALL_X_R ) then
            x3_delta_next <= BALL_V_P;
        -- right corner of ball inside bar
        elsif ((BAR_X_L <= ball3_x_r) and (ball3_x_r <= BAR_X_R)) then
        -- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= ball3_y_b) and (ball3_y_t <= bar_y_b)) then
                x3_delta_next <= BALL_V_N;
            end if;
        end if;
    end process;

    process (video_on, wall_on, bar_on, rd_ball1_on, rd_ball1_on, rd_ball1_on, wall_rgb, bar_rgb, ball_rgb)
    begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            elsif (bar_on = '1') then
                graph_rgb <= bar_rgb;
            elsif (rd_ball1_on = '1') then
                graph_rgb <= ball_rgb;
            elsif (rd_ball2_on = '1') then
                graph_rgb <= ball_rgb;
            elsif (rd_ball3_on = '1') then
                graph_rgb <= ball_rgb;
            else
                graph_rgb <= "110"; -- yellow bkgnd
            end if;
        end if;
    end process;
end sq_ball_arch;

   