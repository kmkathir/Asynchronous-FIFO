// Code your design here
module async_fifo #(parameter DATA_WIDTH = 8)(
 //write clock domain 
  input wclk,
  input wrst_n,// wrst_n is active-low write reset (reset when wrst_n = 0)
  input w_en,
  input [DATA_WIDTH-1:0]data_in,
  output reg full,
 //read clock domain
   input  rclk,
   input  rrst_n,
   input  r_en,
   output reg [DATA_WIDTH-1:0]data_out,
   output reg empty
);
 //fifo parameters
  parameter ADDR_WIDTH=3;
  parameter DEPTH =8;
 //fifo memory
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
//write pointers
  reg[ADDR_WIDTH:0] b_wptr;
  reg[ADDR_WIDTH:0] g_wptr;     //the extra bit (msb) is wrap bit
  reg[ADDR_WIDTH:0] b_wptr_next;
  reg[ADDR_WIDTH:0] g_wptr_next;
//read pointers
  reg[ADDR_WIDTH:0] b_rptr;
  reg[ADDR_WIDTH:0] g_rptr;     //the extra bit (msb) is wrap bit
  reg[ADDR_WIDTH:0] b_rptr_next;
  reg[ADDR_WIDTH:0] g_rptr_next;  
// synchronize read pointer into write clock domain
  reg[ADDR_WIDTH:0] g_rptr_sync1;
  reg[ADDR_WIDTH:0] g_rptr_sync2;
// synchronize write pointer into read clock domain 
  reg[ADDR_WIDTH:0] g_wptr_sync1;
  reg[ADDR_WIDTH:0] g_wptr_sync2;

//writer pointer logic 
  always@(*)
  begin
  //nextstate
 b_wptr_next = b_wptr;
    if (w_en && !full)
       b_wptr_next = b_wptr + 1'b1;
//binary to gray 
    g_wptr_next=b_wptr_next^(b_wptr_next>>1);
  end
//write pointer registers
  always@(posedge wclk or negedge wrst_n)
    begin
      if(!wrst_n)
        begin
          b_wptr <=0;
          g_wptr <=0;
        end
      else
        begin
          b_wptr <= b_wptr_next;
          g_wptr <= g_wptr_next;
        end
    end
          
//read pointer logic
  always@(*)
    begin
  //nextstate
      if(r_en && !empty)
        b_rptr_next=b_rptr+1'b1;
      else
        b_rptr_next=b_rptr;
  //binary to gray
      g_rptr_next=b_rptr_next^(b_rptr_next>>1);
    end
//read pointer register
  always@(posedge rclk or negedge rrst_n)
    begin
      if(!rrst_n) 
    begin
        b_rptr <=0;
        g_rptr <=0;
    end
  else
    begin
      b_rptr <=b_rptr_next;
      g_rptr <=g_rptr_next;
    end
  end

//sync read pointer into write clock domain
  always@(posedge wclk or negedge wrst_n)
    begin
      if(!wrst_n)
        begin
          g_rptr_sync1 <=0;
          g_rptr_sync2 <=0;
        end
      else
        begin
          g_rptr_sync1 <=g_rptr;
          g_rptr_sync2 <=g_rptr_sync1;
        end
    end

//sync write pointer into read clock domain
  always@(posedge rclk or negedge rrst_n)
    begin
      if(!rrst_n)
        begin
          g_wptr_sync1 <=0;
          g_wptr_sync2 <=0;
       end
     else
         begin
           g_wptr_sync1 <= g_wptr;
           g_wptr_sync2 <= g_wptr_sync1;
         end
    end

//Empty flag logic  
  always@(posedge rclk or negedge rrst_n)
    begin
      if(!rrst_n)
        begin
          empty<=1'b1;
        end
      else if(g_rptr_next == g_wptr_sync2) 
        begin
          empty<=1'b1;
        end
      else
        empty<=1'b0;
  end
//Full flag logic
wire full_condition;

assign full_condition =
    (g_wptr_next ==
     {~g_rptr_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
      g_rptr_sync2[ADDR_WIDTH-2:0]});
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)
        full <= 1'b0;
    else
        full <= full_condition;
end

                  
// fifo memory write logic
  always@(posedge wclk)
    begin
      if(w_en && !full)
        begin
          mem[b_wptr[ADDR_WIDTH-1:0]] <=data_in;
              end
    end

//fifo read logic
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)
        data_out <= 0;
    else if (r_en && !empty)
        data_out <= mem[b_rptr[ADDR_WIDTH-1:0]];
end
   
endmodule


   
 
