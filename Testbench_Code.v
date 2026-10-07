
`timescale 1ns/1ps

module tb_async_fifo;
  reg  wclk;
  reg  rclk;
  reg  wrst_n;
  reg  rrst_n;
  reg  w_en;
  reg  r_en;
  reg  [7:0] data_in;

  wire [7:0] data_out;
  wire full;
  wire empty;

//instantiaton fifo
  async_fifo dut (.wclk(wclk),.wrst_n(wrst_n),.w_en(w_en),.data_in(data_in),.full(full),.rclk(rclk),.rrst_n(rrst_n),.r_en(r_en),.data_out(data_out),.empty(empty));
//write clk->fast (75 MHz)
  initial begin
    wclk = 0;
    forever #6.666 wclk = ~wclk;
  end

//read clk ->slow (25 MHz)
  initial begin
    rclk = 0;
    forever #20 rclk = ~rclk;
  end

//reset
  initial 
   begin
    wrst_n  = 0;
    rrst_n  = 0;
    w_en    = 0;
    r_en    = 0;
    data_in = 8'h00;
    #40;
    wrst_n = 1;
    rrst_n = 1;
  end

//write process
  initial 
   begin
    @(posedge wrst_n);
    #20;
    repeat (10) begin
      @(posedge wclk);
      if (!full) begin
        w_en    <= 1;
        data_in <= data_in + 1;
      end
      else begin
        w_en <= 0;
      end
    end
    w_en <= 0;
  end

//read process  
  initial begin
    @(posedge rrst_n);
    #100;
    r_en = 0;

    wait (!empty);          // wait until data reaches read domain

    while (!empty) begin
      @(posedge rclk);
      r_en <= 1;
    end

    @(posedge rclk);
    r_en <= 0;
  end

  initial begin
    $display("time  w_en r_en data_in data_out full empty");
    $monitor("%4t   %b    %b     %h      %h     %b     %b",$time, w_en, r_en, data_in, data_out, full, empty);
  end

  initial 
   begin
     $dumpfile("waveform.vcd");
    $dumpvars(0,tb_async_fifo);
    #1500;
    $finish;
  end

endmodule
