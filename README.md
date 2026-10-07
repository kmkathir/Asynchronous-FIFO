# Asynchronous-FIFO

# 8×32 Asynchronous FIFO Design

## 📌 Project Overview

This project implements an **8-bit wide, 32-depth Asynchronous FIFO (First-In First-Out)** using **Verilog HDL**.

An asynchronous FIFO is used to safely transfer data between two different clock domains where the **write clock and read clock are independent of each other**.

The design uses separate write and read control logic and **Gray-code pointers** for reliable clock-domain crossing.

---

## 📐 FIFO Specifications

| Parameter     |               Value |
| ------------- | ------------------: |
| Data Width    |              8 bits |
| FIFO Depth    |        32 locations |
| Total Storage | 256 bits / 32 bytes |
| Address Width |              5 bits |
| Pointer Width |              6 bits |
| Write Clock   |         Independent |
| Read Clock    |         Independent |
| HDL           |             Verilog |

### What does 8×32 mean?

* **8** → Each FIFO location stores **8 bits of data**
* **32** → FIFO contains **32 storage locations**

Therefore:

```text
Total storage = 8 × 32 = 256 bits = 32 bytes
```

---

## 🧠 What is an Asynchronous FIFO?

A normal FIFO transfers data in the order:

```text
First Data In → First Data Out
```

An **asynchronous FIFO** is a FIFO in which the write and read operations are controlled by **different clock domains**.

```text
             WRITE CLOCK
                  │
                  ▼
            ┌───────────┐
Data ──────►│   FIFO    │──────► Data Out
            │  Memory   │
            └───────────┘
                  ▲
                  │
             READ CLOCK
```

For example:

```text
Write Clock = 100 MHz
Read Clock  = 75 MHz
```

The two clocks do not need to have the same frequency or phase.

---

## 🏗️ Architecture

The FIFO consists of the following major blocks:

```text
                 WRITE CLOCK DOMAIN
                         │
                         ▼
                  ┌─────────────┐
                  │ Write Logic │
                  └──────┬──────┘
                         │
                  Binary Write
                     Pointer
                         │
                         ▼
                    Gray Pointer
                         │
                         │ Synchronization
                         ▼
                  ┌─────────────┐
                  │ Read Domain │
                  └─────────────┘


                  ┌─────────────┐
Write Data ──────►│ FIFO Memory │──────► Read Data
                  └─────────────┘


                  READ CLOCK DOMAIN
                         │
                         ▼
                  ┌─────────────┐
                  │  Read Logic │
                  └──────┬──────┘
                         │
                   Binary Read
                     Pointer
                         │
                         ▼
                    Gray Pointer
                         │
                         │ Synchronization
                         ▼
                  ┌─────────────┐
                  │ Write Domain│
                  └─────────────┘
```

---

## 🔑 Main Concepts Used

### 1. FIFO Memory

The memory contains **32 locations**, with each location storing **8 bits**.

```text
Location 0  → 8 bits
Location 1  → 8 bits
Location 2  → 8 bits
   .
   .
   .
Location 31 → 8 bits
```

Conceptually:

```verilog
reg [7:0] mem [0:31];
```

---

### 2. Write Pointer

The write pointer identifies the memory location where the next data will be written.

Since there are 32 locations:

```text
2^5 = 32
```

Therefore, **5 address bits** are required.

However, an additional MSB is used for FIFO full/empty detection, making the pointer **6 bits wide**.

```text
Pointer = 6 bits
Address = lower 5 bits
Extra MSB = wrap-around information
```

---

### 3. Read Pointer

The read pointer identifies the memory location from which the next data will be read.

Similar to the write pointer:

```text
Read Pointer = 6 bits
Address      = lower 5 bits
Extra MSB    = wrap-around information
```

---

## 🔄 Binary to Gray Code

One of the important features of an asynchronous FIFO is the use of **Gray-code pointers** for clock-domain crossing.

In binary, multiple bits can change at the same time.

For example:

```text
0111 → 1000
```

Four bits change simultaneously.

This can create problems when the pointer is transferred between asynchronous clock domains.

In Gray code, only **one bit changes between consecutive values**.

The conversion is:

```text
Gray = Binary ^ (Binary >> 1)
```

Example:

```text
Binary = 0011

Gray   = 0011 ^ 0001
       = 0010
```

The Gray-coded pointer is then synchronized into the opposite clock domain.

---

## 🔄 Clock Domain Crossing

The write pointer belongs to the **write clock domain**, while the read pointer belongs to the **read clock domain**.

Therefore, they cannot be directly used in the opposite clock domain.

The design uses **synchronizer flip-flops** to transfer the Gray-coded pointer safely.

```text
Write Domain                    Read Domain

Binary Write Pointer
        │
        ▼
Gray Write Pointer
        │
        ▼
   Synchronizer ───────────────► Synchronized
                                 Write Pointer
```

Similarly:

```text
Read Domain                     Write Domain

Binary Read Pointer
        │
        ▼
Gray Read Pointer
        │
        ▼
   Synchronizer ───────────────► Synchronized
                                  Read Pointer
```

---

## 🚦 FIFO Empty Condition

The FIFO is **empty** when the read pointer reaches the synchronized write pointer.

Conceptually:

```text
Read Pointer == Synchronized Write Pointer
```

When this condition is true:

```text
empty = 1
```

No valid data is available to read.

---

## 🚦 FIFO Full Condition

The FIFO is **full** when the write pointer has advanced one complete FIFO cycle ahead of the read pointer.

The additional pointer bit helps identify this wrap-around condition.

When the FIFO is full:

```text
full = 1
```

Further writes should be prevented until data is read.

---

## 🔁 FIFO Operation

### Write Operation

When:

```text
write_enable = 1
full = 0
```

the FIFO:

1. Stores input data into memory.
2. Increments the write pointer.
3. Converts the binary pointer to Gray code.
4. Synchronizes the pointer into the read clock domain.

Example:

```text
write_data = 8'b10101010

Memory[write_address] = 10101010
```

---

### Read Operation

When:

```text
read_enable = 1
empty = 0
```

the FIFO:

1. Reads data from memory.
2. Updates the read pointer.
3. Converts the pointer to Gray code.
4. Synchronizes the pointer into the write clock domain.

---
