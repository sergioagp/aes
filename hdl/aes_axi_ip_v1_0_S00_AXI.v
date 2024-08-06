
`timescale 1 ns / 1 ps

	module aes_axi_ip_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 8
	)
	(
		// Users to add ports here
        output wire           rmem_en,
        output wire           rmem_we,
        output wire  [31:0]   rmem_addr,
        output wire  [31:0]   rmem_din,
        input wire   [31:0]   rmem_dout,

        output wire           wmem_en,
        output wire           wmem_we,
        output wire  [31:0]   wmem_addr,
        output wire  [31:0]   wmem_din,
        input wire   [31:0]   wmem_dout,

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 5;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index,i;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;

    //----------------------------------------------------------------
    // Internal constant and parameter definitions.
    //----------------------------------------------------------------
    localparam ADDR_NAME0       = 8'h00;
    localparam ADDR_NAME1       = 8'h01;
    localparam ADDR_VERSION     = 8'h02;

    localparam ADDR_CTRL        = 8'h08;
    localparam CTRL_INIT_BIT    = 0;
    localparam CTRL_NEXT_BIT    = 1;

    localparam ADDR_STATUS      = 8'h09;
    localparam STATUS_READY_BIT = 0;
    localparam STATUS_VALID_BIT = 1;

    localparam ADDR_CONFIG      = 8'h0a;
    localparam CTRL_ENCDEC_BIT  = 0;
    localparam CTRL_KEYLEN_BIT  = 1;

    localparam ADDR_KEY0        = 8'h10;
    localparam ADDR_KEY1        = 8'h11;
    localparam ADDR_KEY2        = 8'h12;
    localparam ADDR_KEY3        = 8'h13;
    localparam ADDR_KEY4        = 8'h14;
    localparam ADDR_KEY5        = 8'h15;
    localparam ADDR_KEY6        = 8'h16;
    localparam ADDR_KEY7        = 8'h17;

    localparam ADDR_BLOCK0      = 8'h20;
    localparam ADDR_BLOCK1      = 8'h21;
    localparam ADDR_BLOCK2      = 8'h22;
    localparam ADDR_BLOCK3      = 8'h23;

    localparam ADDR_RESULT0     = 8'h30;
    localparam ADDR_RESULT1     = 8'h31;
    localparam ADDR_RESULT2     = 8'h32;
    localparam ADDR_RESULT3     = 8'h33;

    localparam CORE_NAME0       = 32'h61657320; // "aes "
    localparam CORE_NAME1       = 32'h20202020; // "    "
    localparam CORE_VERSION     = 32'h302e3630; // "0.60"

    //----------------------------------------------------------------
    // Registers including update variables and write enable.
    //----------------------------------------------------------------
    reg init_reg;
    reg init_new;

    reg next_reg;
    reg next_new;

    reg encdec_reg;
    reg keylen_reg;
    reg config_we;

    reg [31 : 0] block_reg [0 : 3];
    reg          block_we;

    reg [31 : 0] key_reg [0 : 7];
    reg          key_we;

    reg [127 : 0] result_reg;
    reg           valid_reg;
    reg           ready_reg;


    //----------------------------------------------------------------
    // Wires.
    //----------------------------------------------------------------
    wire           core_encdec;
    wire           core_init;
    wire           core_next;
    wire           core_ready;
    wire [255 : 0] core_key;
    wire           core_keylen;
    wire [127 : 0] core_block;
    wire [127 : 0] core_result;
    wire           core_valid;


    wire [31 : 0]   CORE_CTRL;
    wire [31 : 0]   CORE_STATUS;
    wire [31 : 0]   CORE_CONFIG;
    wire [31 : 0]   CORE_KEY0;
    wire [31 : 0]   CORE_KEY1;
    wire [31 : 0]   CORE_KEY2;
    wire [31 : 0]   CORE_KEY3;
    wire [31 : 0]   CORE_KEY4;
    wire [31 : 0]   CORE_KEY5;
    wire [31 : 0]   CORE_KEY6;
    wire [31 : 0]   CORE_KEY7;
    wire [31 : 0]   CORE_BLOCK0;
    wire [31 : 0]   CORE_BLOCK1;
    wire [31 : 0]   CORE_BLOCK2;
    wire [31 : 0]   CORE_BLOCK3;
    wire [31 : 0]   CORE_RESULT0;
    wire [31 : 0]   CORE_RESULT1;
    wire [31 : 0]   CORE_RESULT2;
    wire [31 : 0]   CORE_RESULT3;




//----------------------------------------------------------------
// Whenever the next_reg is set or core_ready & core_valid are high
// the core_block is read from the BRAM and the address is incremented (during next_reg the addr is zeroed)
//----------------------------------------------------------------
localparam BLK_COUNTER_MAX = 4'h4;
localparam RMEM_ST_IDLE = 0;
localparam RMEM_ST_RD_B = 1;
localparam RMEM_ST_WAIT = 2;
localparam RMEM_ST_TRIG = 3;

wire wmem_done;

// Regs and wires to connect the IP to the DATA BRAM
reg [3:0]     rmem_st;
wire core_trig;

reg [27:0]  rmem_blk_count;
reg [1:0]  rmem_addr_reg;
reg [31:0] rmem_data_reg  [0:3];

// bram_din din_mem (
//   .clka(S_AXI_ACLK),     // input wire clka
//   .ena(din_mem_en),      // input wire ena
//   .wea(din_mem_we),      // input wire [0 : 0] wea
//   .addra(din_mem_din_addr),  // input wire [3 : 0] addra
//   .dina(din_mem_din),    // input wire [127 : 0] dina
//   .douta(din_mem_dout)  // output wire [127 : 0] douta
// );

assign rmem_en = 1'b1;  //next_reg || (core_ready && core_valid);
assign rmem_we = 1'b0;
assign rmem_addr = {rmem_blk_count, rmem_addr_reg, 2'h0};
assign rmem_din = 32'h0;

wire [27:0] rmem_blk_len;  // Indicates the length (number of bytes) of a received block

assign rmem_blk_len = block_reg[1][31:4];

always @ (posedge S_AXI_ACLK)
begin
    if (S_AXI_ARESETN == 1'b0)
        begin
            rmem_st <= RMEM_ST_IDLE;

            rmem_blk_count <= 28'h0;
            rmem_addr_reg <= 2'h0;

            rmem_data_reg[0] <= 32'h0;
            rmem_data_reg[1] <= 32'h0;
            rmem_data_reg[2] <= 32'h0;
            rmem_data_reg[3] <= 32'h0;
        end
    else
        begin

            case (rmem_st)
                RMEM_ST_IDLE:
                    begin
                        if(init_reg)
                            begin
                                rmem_blk_count  <= 28'h0;
                                rmem_addr_reg   <= 2'h0;
                            end

                        if (next_reg || (wmem_done && rmem_blk_count != rmem_blk_len))
                            begin
                                rmem_st <= RMEM_ST_RD_B;
                            end
                    end
                RMEM_ST_RD_B:
                    begin
                        rmem_st <= (rmem_addr_reg == 2'h3)? RMEM_ST_TRIG : RMEM_ST_WAIT;
                        rmem_addr_reg <= rmem_addr_reg + 1;
                        rmem_data_reg[rmem_addr_reg] <= rmem_dout; 
                    end
                RMEM_ST_WAIT:
                    begin
                        rmem_st <= RMEM_ST_RD_B;
                    end
                RMEM_ST_TRIG:
                    begin
                        rmem_st <= RMEM_ST_IDLE;
                        rmem_blk_count <= rmem_blk_count + 1;
                    end
                default: begin
                    rmem_st        <= RMEM_ST_IDLE;
                    rmem_blk_count <= 28'h0;
                    rmem_addr_reg  <= 2'h0;
                end
            endcase
        end
end

assign core_trig = (rmem_st == RMEM_ST_TRIG);

//----------------------------------------------------------------
// Whenever a result is valid, it is written to the BRAM
//----------------------------------------------------------------
localparam WMEM_ST_IDLE = 0;
localparam WMEM_ST_WAIT = 1;
localparam WMEM_ST_WD_R = 2;
localparam WMEM_ST_DONE = 3;

// Regs and wires to connect the IP to the DATA BRAM
reg [3:0]     wmem_st;

reg [27:0]  wmem_blk_count;
reg [1:0]  wmem_addr_reg;
reg [31:0] wmem_data_reg [0:3];

assign wmem_en = 1'b1;  //next_reg || (core_ready && core_valid);
assign wmem_addr = {wmem_blk_count, wmem_addr_reg, 2'h0};
assign wmem_we = (wmem_st == WMEM_ST_WD_R);
assign wmem_din = wmem_data_reg[wmem_addr_reg];

always @ (posedge S_AXI_ACLK)
begin
    if (S_AXI_ARESETN == 1'b0)
        begin
            wmem_st <= WMEM_ST_IDLE;
            wmem_blk_count <= 28'h0;
            wmem_addr_reg <= 2'h0;
            wmem_data_reg[0] <= 32'h0;
            wmem_data_reg[1] <= 32'h0;
            wmem_data_reg[2] <= 32'h0;
            wmem_data_reg[3] <= 32'h0;
        end
    else
        begin

            case (wmem_st)
                WMEM_ST_IDLE:
                    begin
                        if(init_reg)
                            begin
                                wmem_blk_count  <= 28'h0;
                                wmem_addr_reg   <= 2'h0;
                            end
                        if (core_trig) // wait for the core to trigger processing
                            begin
                                wmem_st <= WMEM_ST_WAIT;
                            end
                    end
                WMEM_ST_WAIT:
                    begin
                        if (core_valid) // wait for the core to finish processing
                            begin
                                wmem_data_reg[0] <= core_result[127:96];
                                wmem_data_reg[1] <= core_result[95:64];
                                wmem_data_reg[2] <= core_result[63:32];
                                wmem_data_reg[3] <= core_result[31:0];
                                wmem_st <= WMEM_ST_WD_R;
                            end
                    end
                WMEM_ST_WD_R:
                    begin
                        wmem_st <= (wmem_addr_reg == 2'h3)?  WMEM_ST_DONE : WMEM_ST_WD_R;       
                        wmem_addr_reg <= wmem_addr_reg + 1;
                    end
                WMEM_ST_DONE:
                    begin
                        wmem_st <= WMEM_ST_IDLE;
                        wmem_blk_count <= wmem_blk_count + 1;
                    end
                default: begin
                    wmem_blk_count <= 28'h0;
                    wmem_addr_reg <= 2'h0;
                    
                    wmem_data_reg[0] <= 32'h0;
                    wmem_data_reg[1] <= 32'h0;
                    wmem_data_reg[2] <= 32'h0;
                    wmem_data_reg[3] <= 32'h0;
                    wmem_st <= WMEM_ST_IDLE;
                end
            endcase
        end
end

assign wmem_done = (wmem_st == WMEM_ST_DONE);

//----------------------------------------------------------------
// Concurrent connectivity for ports etc.
//----------------------------------------------------------------
assign core_key = {key_reg[0], key_reg[1], key_reg[2], key_reg[3],
                    key_reg[4], key_reg[5], key_reg[6], key_reg[7]};

// assign core_block  = {block_reg[0], block_reg[1],
//                     block_reg[2], block_reg[3]};

assign core_block  = {rmem_data_reg[0], rmem_data_reg[1],
                    rmem_data_reg[2], rmem_data_reg[3]};
assign core_init   = init_reg;
assign core_next   = core_trig; // next_reg;
assign core_encdec = encdec_reg;
assign core_keylen = keylen_reg;

//----------------------------------------------------------------
// core instantiation.
//----------------------------------------------------------------
aes_core core(
    .clk(S_AXI_ACLK),
    .reset_n(S_AXI_ARESETN),

    .encdec(core_encdec),
    .init(core_init),
    .next(core_next),
    .ready(core_ready),

    .key(core_key),
    .keylen(core_keylen),

    .block(core_block),
    .result(core_result),
    .result_valid(core_valid)
);

    assign CORE_CTRL    = {28'h0, keylen_reg, encdec_reg, core_trig, init_reg};
    assign CORE_STATUS  = {30'h0, valid_reg, ready_reg};
    assign CORE_CONFIG  = {30'h0, keylen_reg, encdec_reg};
    assign CORE_KEY0    = key_reg[0];
    assign CORE_KEY1    = key_reg[1];
    assign CORE_KEY2    = key_reg[2];
    assign CORE_KEY3    = key_reg[3];
    assign CORE_KEY4    = key_reg[4];
    assign CORE_KEY5    = key_reg[5];
    assign CORE_KEY6    = key_reg[6];
    assign CORE_KEY7    = key_reg[7];
    assign CORE_BLOCK0  = block_reg[0];
    assign CORE_BLOCK1  = block_reg[1];
    assign CORE_BLOCK2  = {2'h0, rmem_blk_count, rmem_addr_reg};
    assign CORE_BLOCK3  = {2'h0, wmem_blk_count, wmem_addr_reg};
    assign CORE_RESULT0 = result_reg[127:96];
    assign CORE_RESULT1 = result_reg[95:64];
    assign CORE_RESULT2 = result_reg[63:32];
    assign CORE_RESULT3 = result_reg[31:0];

//----------------------------------------------------------------
//////////////////USER LOGIC ENDS HERE////////////////////////////
//----------------------------------------------------------------


	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if (S_AXI_ARESETN == 1'b0 )
	    begin
            init_reg   <= 1'b0;
            next_reg   <= 1'b0;
            encdec_reg <= 1'b0;
            keylen_reg <= 1'b0;

          for (i = 0 ; i < 4 ; i = i + 1)
            block_reg[i] <= 32'h0;

          for (i = 0 ; i < 8 ; i = i + 1)
            key_reg[i] <= 32'h0;

            result_reg <= 128'h0;
            valid_reg  <= 1'b0;
            ready_reg  <= 1'b0;
	    end 
	  else begin
        ready_reg  <= core_ready;
        valid_reg  <= core_valid;
        result_reg <= core_result;
        init_reg   <= init_new;
        next_reg   <= next_new;

	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          ADDR_CONFIG:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 10
	                //slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    encdec_reg <= S_AXI_WDATA[CTRL_ENCDEC_BIT];
                    keylen_reg <= S_AXI_WDATA[CTRL_KEYLEN_BIT];
	              end  
	          ADDR_KEY0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[0][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          ADDR_KEY1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[1][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          ADDR_KEY2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[2][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
              ADDR_KEY3:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 16
                    // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[3][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
	          ADDR_KEY4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[4][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          ADDR_KEY5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[5][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          ADDR_KEY6:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[6][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
              ADDR_KEY7:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 16
                    // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    key_reg[7][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
	          ADDR_BLOCK0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    block_reg[0][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          ADDR_BLOCK1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    block_reg[1][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          ADDR_BLOCK2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 16
	                // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    block_reg[2][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
              ADDR_BLOCK3:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes 
                    // Slave register 16
                    // slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    block_reg[3][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
	          default : begin
	                    end
	        endcase
	      end
	  end
	end


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
        init_new      = 1'b0;
        next_new      = 1'b0;

        if (slv_reg_wren && S_AXI_ARESETN != 1'b0)
        begin
            if (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == ADDR_CTRL)
            begin
                init_new = S_AXI_WDATA[CTRL_INIT_BIT];
                next_new = S_AXI_WDATA[CTRL_NEXT_BIT];
            end
        end // if (we)
    end // addr_decoder




	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        ADDR_NAME0      : reg_data_out <= CORE_NAME0;
	        ADDR_NAME1      : reg_data_out <= CORE_NAME1;
	        ADDR_VERSION    : reg_data_out <= CORE_VERSION;
	        ADDR_CTRL       : reg_data_out <= CORE_CTRL;
	        ADDR_STATUS     : reg_data_out <= CORE_STATUS;
	        ADDR_CONFIG     : reg_data_out <= CORE_CONFIG;
	        ADDR_KEY0       : reg_data_out <= CORE_KEY0;
	        ADDR_KEY1       : reg_data_out <= CORE_KEY1;
	        ADDR_KEY2       : reg_data_out <= CORE_KEY2;
	        ADDR_KEY3       : reg_data_out <= CORE_KEY3;
	        ADDR_KEY4       : reg_data_out <= CORE_KEY4;
	        ADDR_KEY5       : reg_data_out <= CORE_KEY5;
	        ADDR_KEY6       : reg_data_out <= CORE_KEY6;
	        ADDR_KEY7       : reg_data_out <= CORE_KEY7;
	        ADDR_BLOCK0     : reg_data_out <= CORE_BLOCK0;
	        ADDR_BLOCK1     : reg_data_out <= CORE_BLOCK1;
	        ADDR_BLOCK2     : reg_data_out <= CORE_BLOCK2;
	        ADDR_BLOCK3     : reg_data_out <= CORE_BLOCK3;
	        ADDR_RESULT0    : reg_data_out <= CORE_RESULT0;
	        ADDR_RESULT1    : reg_data_out <= CORE_RESULT1;
	        ADDR_RESULT2    : reg_data_out <= CORE_RESULT2;
	        ADDR_RESULT3    : reg_data_out <= CORE_RESULT3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    


	endmodule
