##  DevLog Of MAGE

### 3.1

#### Done : 分析 .sgx_mage section

```shell
readelf -x .sgx_mage libencalve1.so
```

![image-20220301135923807](C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220301135923807.png)

我们可以发现，.sgx_mage section 内容包括从 0x28000 地址开始的 152 个字节

= 144 + sizeof(sgx_mage_t)  

额外用了八个字节来存储 entry 的个数

![image-20220301140127294](C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220301140127294.png)

与我们在 makefile `SIGNMAGE` 中看到的输出信息一致







### 2.27

#### Done ：编译运行 MutualAttestation Sample Code

- 编译通过

- :star:  运行 `source $(sdk_path)/environment` ，主要目的在于设置 `LD_LIBRARY_PATH` ，加入自己的动态链接库所在路径

- 执行 `make SGX_MODE=SIM` `./app`

- 结果如下

  ![image-20220227152847879](C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220227152847879.png)





#### Done : 搞清楚 App 编译过程

一个完整的 sgx App 包含 `encalve.cpp` `enclave.edl`  `enclave.lds` `enclave_private.pem`  `enclave.config.xml`  `App.cpp`



.edl 文件中定义了 ecall 和 ocall 的接口，只有在里面定义的函数才能执行 ecall / ocall 的任务，

所有传入的指针都必须指定 size，sgx 会有一个 sgxedger8r 工具，用于根据 edl 生成对应的 .c 和 .h 文件。

其中，命名为 enclave_t.h 和 enclave_t.c 的文件用于给 Enclave 文件使用，执行指针边界检查，相当于在 encalve.cpp 前面加一块代码，然后一起链接生成 enclave.so 文件

而命名为 encalve_u.h 和 enclave_u.c 的文件用于给 App 文件使用，同样用于执行边界检查，相当于在 app 前面加一块代码，即 enclave_u.o，然后和 app.o 一起链接生成 app 可执行文件





### 2.26

#### Done : 编译 psw

- make 的时候注意需要设置 `SGX_SDK` ==环境==变量

  ```shell
  $ export SGX_SDK=PATH
  ```

  

- 编译通过



#### Done ：编译 sdk

- 编译通过



### 2.25

#### Todo ：对比 2.15 和 2.6 的 signtool 部分

- `signtool.cpp`
  - 增加一个 resign 的选项







#### Done : 完成 sdk/sign_tool 部分的修改

- [x] `util_st.h`

- [x] `util_st.cpp`

- [x] `parser_key_file.cpp`

- [x] `enclave_creator_sign.h`

- [x] `encalve_creator_sign.cpp`

  > 在添加一个 page 时，会先 EADD，然后 EEXTEND
  >
  > 其中， EADD 时，会构建这样一个 512 bit 的块，其中保存了一些信息，然后先 measure 它
  >
  > <img src="C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220225163738160.png" alt="image-20220225163738160" style="zoom:67%;" />
  >
  > ![image-20220225163751504](C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220225163751504.png)
  >
  > 注意这个地方的三次 memcpy 就是在分别写入这三部分内容
  >
  > EEXTEND  同理

- [x] `sign_tool.cpp`





#### Done : 完成 sgx_mage.h 和 sgx_mage.cpp 的移植







#### Done : Problem

- 函数参数的默认值可以像上面的 Function1 那样写在声明函数的地方，也可以像 Function2 那样写在定义函数的地方，但是不能在两个地方都写。





### 2.24

#### Done : enclave [mage] 编译过程分析

##### 2.15 版本

- SGX_ENCLAVE_SIGNER ：`$(SGX_SDK)/bin/x86/sgx_sign`

- 为 enclave 签名的指令

  ```
  $(SGX_ENCLAVE_SIGNER) sign -key <key1> -enclave Enclave1.so -out <$(Enclave_Name_1)> -config Enclave1/Enclave1.config.xml
  ```

- `genmage` `signmage` 是他给签名工具额外中增加的两个指令



大致流程：

源文件 (.h, .cpp)  -> .o -> .so -> genmage  ->  signmage -> libenclave.so

最后加载运行的是  libenclave.so



- ==搞清楚 mage.bin 的作用==  （Solved）



- genmage : Generate enclave material for mutual attestation

- signmage : Sign enclave with mutual attestation



##### sigtool.cpp

- cmdline_parser

  首先通过参数对比，确定用户选择的模式，如 `genmage` , `signmage`，然后进行参数检查

  同时在确定每个  `-option`  后面所需要的文件的路径，填充到 `path` 变量中

  ![image-20220224191640699](C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220224191640699.png)

  

- parse_metadata_file

  `Enclave1.config.xml`  获取一些配置信息

- lparse_key_file 

  `Enclave1_private.pem`    获取 RSA 私钥

- 如果是 GENMAGE 模式

  - 调用 `measure_enclave`， 填补 mage_t 结构体，包括了 mage section 的 offset，该 encalve 的中间 hash 值等，这些值在 `encalve_load` 过程中获得，==通过签名模式的 enclave_creator==
  - 调用 `write_data_to_file`， 以 append 方式写入 MAGE_OUT 文件
  
- 调用 `copy_file` ，将 encalve.so -> libenclave.so

- 如果是 SIGNMAGE 模式
  - 调用 `read_file_to_buf` ，将 MAGE_IN 中的内容写入到一个 `sgx_mage_t` 结构体中 
  - 调用 `measure_enclave` ，感觉应该是为了获得 mage_offset ==待定== 
  - 调用 `write_data_to_file` ，将 `sgx_mage_t` 中的内容写入到 `libencalve.so`  mage section 对应的地方去 
  - 调用 `read_file_to_buf`，这一步应该就是为了将刚才写入的东西读一遍，然后确认是否正确写入








### 2.18 - 2.22

#### Done : 完成 parser 和 loader的修改 (psw/urts)

- [x] `binparser.h`

- [x] `elfparser.h` 

  - 成员变量

    ```c++
        const uint8_t*         m_start_addr;	
        uint64_t               m_len;					// 文件大小
        bin_fmt_t              m_bin_fmt;
        std::vector<Section *> m_sections;
        const Section*         m_tls_section;
        Section*               m_mage_section;
        bool                   m_for_sign;
        uint64_t               m_metadata_offset;
        uint64_t               m_metadata_block_size;
    ```

    >- `m_start_addr` 
    >
    >  是 enclave 文件通过 mmap 映射到内存空间的基址
    >
    >  可在 `psw/urts/urts_com.h`  的 `_create_enclave_ex` 函数中看出
    >
    >  <img src="C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220221212339330.png" alt="image-20220221212339330" style="zoom:67%;" />
    >
    >

- [x]  `elfparser.cpp`

  - build_mage_section

    > 至于为什么 mage_section 需要单独进行 build，我猜是因为别的都是按 segment 来构建的，而 mage 是按 section

    <img src="C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220221211021564.png" alt="image-20220221211021564" style="zoom:80%;" />

    mage_shdr 是 elf section header 的结构体指针，其成员变量见之前的 section header 部分

    `mage_shdr->offset` 指的是 mage section 相对于文件头的偏移量

    `start_addr` 指的是

    

- [x] `section.h` 

  ##### section 中的成员变量的含义

  ```C++
  // 其实从源码来看，这儿的 section 更多的指的应该是 segment
  const uint8_t*  m_start_addr;     		 
  uint64_t        m_raw_data_size;
  uint64_t        m_rva;	
  uint64_t        m_offset;
  uint64_t        m_virtual_size;	
  si_flags_t      m_si_flag;
  ```

  > <img src="C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220221214047059.png" alt="image-20220221214047059" style="zoom:80%;" />
  >
  > 其中 `prg_hdr` 是指向 elf segment header 的指针
  >
  > - `m_start_addr`
  >
  >   该 segment 在内存中的虚拟地址，等于 enclave 在内存空间的起始地址 + 该 section 相对于 enclave 文件头的偏移量，
  >
  >   源码可见 `psw/urts/parser/elfparser.cpp`  中的 `build_regular_section`
  >
  > - 区分 `m_raw_data_size` 和  `m_virtual_size`  
  >
  >   raw_data_size = p_filesz，即该段在文件中的大小
  >
  >   virtual_size = p_memsz，即该段在内存中的大小
  >
  >   > ==解释==
  >   >
  >   > 段在文件中的大小是 p_filesz，在内存中的大小是 p_memsz。如果 p_memsz 大于 p_filesz，在内存中多出的存储空间应填 0 补充，也就是说，段在内存中可以比在文件中占用空间更大；而相反，p_filesz 永远不应该比 p_memsz 大，因为这样的话，内存中就将无法完整地映射段的内容。
  >
  > - `m_rva` 
  >
  >   relevant virtual address，即本段内容的开始位置在进程空间中的虚拟地址
  >
  >   注意区别于 start_addr，因为每个进程的逻辑地址都是一样的，依靠他们各自的页表映射到不同的物理内存
  >
  >   所以我觉得， start_addr 是考虑了多个进程的情况下的地址，而 rva 就是单个进程中的虚拟地址
  >
  > - `m_offset`
  >
  >   即段内容的开始位置相对于文件开头的偏移量

- [x] `section.cpp`

- [x] `loader.cpp`

- [x] `loader.h`







##### sgx 2.15 相对于 2.6 的修改 (parser)

- `binparser.h`

  set_memory_protection 函数参数修改

- `elfparser.cpp`  `elfparser.h`

  set_memory_protection 函数参数修改 ，看起来不需要考虑

- `makefile`

  一点 sign_tool 小修改，不需要考虑

- `update_global_data.cxx`

  加了关于 elrange 的几个函数，==作用未知==







#### Done : ELF 文件相关内容学习

> 可参见 https://zhuanlan.zhihu.com/p/389408697，总结还挺好

从链接和运行的角度，可以将 ELF 文件的组成划分为 链接视图和运行视图两种格式

<img src="C:\Users\HASEE\AppData\Roaming\Typora\typora-user-images\image-20220221180024231.png" alt="image-20220221180024231" style="zoom:67%;" />



==好像 offset 都是相对于文件头的偏移量==

##### file header







##### section header

```c++
typedef struct {
    Elf64_Half    sh_name;      /* section name 存的是偏移量，而不直接指向名字，见后面补充*/
    Elf64_Half    sh_type;      /* section type */
    Elf64_Xword   sh_flags;     /* section flags */
    Elf64_Addr    sh_addr;      /* virtual address  此字段（8 字节）指明本节内容需要映射到进程空间中去的映射起始地址； */
    Elf64_Off     sh_offset;    /* file offset 该值是该节的第一个字节在文件中的位置，即相对于文件开头的偏移量，单位为字节*/
    Elf64_Xword   sh_size;      /* section size 该节大小*/
    Elf64_Half    sh_link;      /* link to another */
    Elf64_Half    sh_info;      /* misc info */
    Elf64_Xword   sh_addralign; /* memory alignment */
    Elf64_Xword   sh_entsize;   /* table entry size  有一些节的内容是一张表，且其中每一个表项的大小是固定的。对于这种表来说，本成员指定其每一个表项的大小。如果此值为 0 则表明本节内容不是这种表项方式进行存储的。 */
} Elf64_Shdr;
```

- 关于 section 名字

  节头的名字都全放在一个专门存储节头名字的节中，这个节的名字是 .shstrtab，找到这个节的起始地址，然后加上数据成员 sh_name 的偏移量，就可以找到对应的节头的名字的存储地址。其中，这个节的起始地址存储在文件头中： `e_shstrndx`





##### program header

> 在运行过程中是必须的，在连接过程中是可选的，因为它的作用是告诉系统如何创建进程的镜像

```c++
typedef struct {
    Elf64_Half     p_type;        /* entry type */
    Elf64_Half     p_flags;       /* flags */
    Elf64_Off      p_offset;      /* offset 此字段（8 字节）给出本段内容在文件中的位置，即段内容的开始位置相对于文件开头的偏移量。 */
    Elf64_Addr     p_vaddr;       /* virtual address 此字段（8 字节）给出本段内容的开始位置在进程空间中的虚拟地址。 */
    Elf64_Addr     p_paddr;       /* physical address 此字段（8 字节）给出本段内容的开始位置在进程空间中的物理地址。对于目前大多数现代操作系统而言，应用程序中段的物理地址事先是不可知的，所以目前这个 成员多数情况下保留不用，或者被操作系统改作它用。*/
    Elf64_Xword    p_filesz;      /* file size 此字段（8 字节）给出本段内容在文件中的大小，单位是字节，可以是 0。*/
    Elf64_Xword    p_memsz;       /* memory size 此字段（8 字节）给出本段内容在内容镜像中的大小，单位是字节，可以是 0。*/
    Elf64_Xword    p_align;       /* memory & file alignment */
} Elf64_Phdr;
```







### 2.16 ~ 2.17

#### Done : 完成 sgx 2.15 和 sgx_mage 2.6 环境搭建

- 成功运行 Mutual Attestation Sample Code

  > 注意需要设置编译选项： `make SGX_MODE=SIM`

  <img src="Mage_devlog_插图/image-20220217220552636.png" alt="image-20220217220552636" style="zoom:67%;" />





#### Done： 复习 git





### 2.12 ~ 2.16 

#### TODO : Question

==Q ： add page 时在何处进行 EEXTEND 进行度量，为何 unused==

==Q : 打补丁和 layout 部分未看懂==

==Q : 如何输出调试和使用 makefile 构建==





#### Done: 将 Mage 与 sgx sdk2.6 对比

##### 头文件

- ```
  ./common/inc/sgx_mage.h
  ./linux/installer/common/sdk/output/package/include/sgx_mage.h
  ./linux/installer/bin/sgxsdk/include/sgx_mage.h
  ```

  在上述位置增加了 sgx_mage.h 其余都一样，引用规则可见 makefile

  ###### sgx_mage.h

  - 定义两个结构

    -  _sgx_mage_entry_t 
    -  _sgx_mage_t

    即 MAINFO 和 MAINFOS

  - 两个 API

    - sgx_mage_get_size

    - sgx_mage_derive_measurement

      > 参考如下算法流程即可

      <img src="Mage_devlog_插图/image-20220213175850075.png" alt="image-20220213175850075" style="zoom:67%;" />

  

  

- sgx_report.h

  measurement 结构体中包含一个16字节的数组用来表示 measurement 

  <img src="Mage_devlog_插图/image-20220213165257188.png" alt="image-20220213165257188" style="zoom:67%;" />



##### psw

- `psw/urts/loader.h`
  
  - 增加 `build_mage_pages` 接口
  
- `psw/urts/loader.cpp` 中的差异
  
  -  在 `build_pages` 中跳过 mage sections
  - 增加 `build_mage_pages` 函数
  - 在 `build_image` 中增加调用 `build_mage_pages` 的部分
  
- `pws/urts/parser/`

  > ==核心的地方在于增加了一个  `offset`，但是说实话感觉没啥用==

  - `binparser.h`

    > 在 BinParser 类中增加了三个关于 mage section 的虚函数

    ![image-20220214191937917](Mage_devlog_插图/image-20220214191937917.png)

  - `section.h `  | `section.cpp`
  
    > 在 Section 类中增加了一个 `m_offset` 成员
    >
    > 以及对应的函数 `get_offset`
    >
    > 同时在 .cpp 中进行了实现，但是目前看下来 offset 没啥用，而且 offset 完全可以手动推算出来
    
  - `elfparser.h`  | `elfparser.cpp`
  
    > elfparser 继承自 binparser
    >
    > 因此，同样增加了三个函数
    >
    > ![image-20220214201012106](Mage_devlog_插图/image-20220214201012106.png)
    >
    > 和两个成员变量
    >
    > ![image-20220214201023390](Mage_devlog_插图/image-20220214201023390.png)
  
    - 增加 `build_mage_section`
  
      根据 section 名字 `.sgx_mage`  来构建 mage section 对象
      
    - `build_section`
    
      函数参数中增加 offset
    
    - `build_regular_sections`
    
      函数中先调用  build_mage_section 来手动构建 mage section
    
      > 由于其他段是根据 case 来筛选的，所以增加一个 mage section 并不会带来负面影响
  







##### sdk

在 sdk/mage/ 中增加了  `sgx_mage.cpp`  和 `Makefile`

`sgx_mage.cpp` 中实现了上述提到的两个 API





##### SignTool











==变量后面带个 ex 是什么意思？==

- 表示 extend

  sgx_create_enclave_ex相对于sgx_create_enclave扩展支持PCL、Switchless模式、[KSS](https://fortanix.com/blog/2018/02/upcoming-intel-sgx-features-explained/)。





#### Todo: encalve 启动过程

##### 宏观流程

- 最外层 API `sgx_create_enclave`

  > SampleCode/MutualAttestation/App/App.cpp
  >
  > ![image-20220213202813242](Mage_devlog_插图/image-20220213202813242.png)

- 进一步调用 `__sgx_create_enclave_ex`

  > psw/urts/linux/urts.cpp
  >
  > <img src="Mage_devlog_插图/image-20220213203243850.png" alt="image-20220213203243850" style="zoom:50%;" />

  > 此函数实现也在该文件中

  以 read only 方式打开 enclave 文件，获得文件句柄 `fd`

- 进一步调用 `_create_enclave_ex`

  > 定义在 psw/urts/urts_com.h

  将 enclave 文件映射到内存中 (通过 mmap)，获得 `map_handle_t* mh`，包括基址和 enclave 文件的大小

  ![image-20220218193215289](Mage_devlog_插图/image-20220218193215289.png)

- 进一步调用 `_create_enclave_from_buffer_ex`

  > 定义在 psw/urts/urts_com.h

  进行一些环境检验工作，包括：

  - `validate_platform()` 
  - 通过 `parser.run_parser()`  验证 elf 文件格式的正确性
  - 中间省略两个不太重要的检查
  - `get_metadata`
  - 省略一步不太重要的 KSS 检查
  - 通过 ` SGXLaunchToken` 向 Launch Enclave 申请一个 SGX Launch Token，用于将来 EINIT 指令

  

- 之后调用 `__create_enclave` 正式进行 enclave 的创建

  > 定义在 psw/urts/urts_com.h

  - 首先由 enclave 文件在内存中的 base addr 和 parser 生成一个 loader 
  
    调用 ` loader.load_enclave_ex` ，将 sections 加载到 page 中，完成初始化过程
  
  - load 成功之后初始化一个 CEnclave 对象 encalve
  
    > `enclave -> initialize`
    >
    > 实现在 psw/urts/enclave.cpp 中
  
  - 将该 enclave 实例添加到 enclave pool 
  
  - 对 ELRANGE 进行布局调整
  
  - 进入 trts 中对 encalve 做一些初始化
  
    > 实现在： psw/urts/enclave_creator_hw_com.cpp
    >
    > <img src="Mage_devlog_插图/image-20220214152339318.png" alt="image-20220214152339318" style="zoom:67%;" />
  





##### 阅读  .so 文件

```shell
readelf -a xxx.so
objdump -d xxx.so
```



##### 关于 elf 文件的补充

在 elf 文件中，存在两个概念， `section`  和 `segment`

- elf 文件中，存在 `ELF header`， `program header`，  `section header` 

  其中   `program header` 对应的是 segments

  而       `section header`  对应的是 sections

> 每个 segment 中可以包含多个 section
>
> 每个 section 可以属于多个 segment 
>
> segment 之间可以有重合的部分

e.g.

- segment 

  > program headers 中定义了所有的 segment
  >
  > 后面的 section to segment mapping 中表示了每个 segment 中所包含的 section
  >
  > ![image-20220219122053742](Mage_devlog_插图/image-20220219122053742.png)

- section

  > ![image-20220219122307995](Mage_devlog_插图/image-20220219122307995.png)









##### CLoader

> psw/urts/loader.cpp

- load_encalve_ex

  > 不断调用 load_encalve 

- load_encalve

  - 对 Loader 的 Metadata 赋值并进行 validate

    获取一些杂项和性质 `sgx_misc_attr`，用于构建 image

  - build_image

    > 就是把所有的 section 加载到 page 中

    - build_secs

      - 对 `m_secs` 中的一些变量赋值

      - 调用 `EnclaveCreatorHW::create_enclave` -> `enclave_create`  -> 然后通过驱动，调用 ECREATE 硬件指令建立 SECS 

        > 拿到了SGX驱动句柄后，将SGX驱动绑定的设备（如/dev/isgx）mmap映射到base_address偏好的位置处，得到映射地址enclave_base
        >
        > 我的理解是，将硬件中的 sgx 安全区域与内存中的虚拟地址进行绑定，一 一映射
        >
        > <u>前面我们有过一个base_addr，那个地址是Enclave文件映射到的地址（用于Enclave信息解析，及后续Enclave文件内容搬到真正的Enclave中去）。这里的m_start_addr（即之后的 enclave_base）目前为NULL，未来会成为Enclave 中 section 真正的起始地址</u>
    
      - 第一次对 `m_secs.mr_enclave` 赋值
    
    - 先保存 `reloc_bitmap`，然后对 elfparser 保存的 enclave 文件 image 打补丁 (暂时不知道在干嘛)
    
    - build_sections

      调用 `build_mem_region -> build_pages` ，对每个 section 加载到内存页中

      需要注意的是，每次加载完一个 section 之后，会在其末尾额外加一个空白 page ，具体作用未知。
    
      <img src="Mage_devlog_插图/image-20220219145002990.png" alt="image-20220219145002990" style="zoom:67%;" />
    
      -  build_pages
    
        > 在 build_page 中进行对 mage section 的跳过
        >
        > 每次 build_page 时，如果正好需要 build 的是  mage section， 那么跳过
        >
        > 如果不是，那么通过调用 driver 指令去 add page 
        >
        
      - `build_mem_region` -> `build_pages` | `build_partial_pages` -> `EnclaveCreatorHW::add_enclave_page` -> `enclave_load_data` ->
    
        `int ret = ioctl(s_hdevice, SGX_IOC_ENCLAVE_ADD_PAGE, &addp);`
    
    - build_contexts  利用布局信息，构建堆和线程上下文，暂时跳过
    
    - build_mage_pages
    
      > 等其它 section 全部加载完毕后调用
    
    - init_enclave 调用 `EINIT` 完成 enclave 的初始化
    



##### meta data 元数据

<img src="Mage_devlog_插图/image-20220218200246929.png" alt="image-20220218200246929" style="zoom:67%;" />

get_metadata 只在_create_enclave_from_buffer_ex中出现过。目的是通过元数据和sgx_misc_attr向[LaunchEnclave](https://blog.csdn.net/clh14281055/article/details/107919383)获得一个LaunchToken，用于后续的EINIT硬件指令能够确保这个Enclave是可信的启动的。









#### Done: EnclaveCreator

> 头文件位于  common/inc/internal/enclave_creator.h，为硬件模式，模拟模式，和 sign 模式提供统一接口
>
> 如，硬件模式，声明位于 `psw/urts/enclave_creator_hw.h`  定义位于 `psw/urts/linux/enclave_creator_hw.cpp` 

> 应该是用于调用底层的驱动，进一步调用硬件指令

<img src="Mage_devlog_插图/image-20220214150310449.png" alt="image-20220214150310449" style="zoom:67%;" />

 

==通过ioctl与SGX驱动通信==









### ~ - 2.11

#### Done：复习 MAGE Paper

- The key observation is that a measurement, which is the cryptographic hash of an enclave’s code and data, is calculated deterministically and sequentially.

- Measurement 计算

  - A_i

  ![image-20220212174033825](Mage_devlog_插图/image-20220212174033825.png)

  - C_i 表示 enclave 原本的 data + code 

  - 一个 enclave 的 measurement  

    ![image-20220212174141067](Mage_devlog_插图/image-20220212174141067.png)

  - F 用于从 i 的 measurement 中生成 j 的 measurement 

  ![image-20220212174040048](Mage_devlog_插图/image-20220212174040048.png)



- - MARS (*mutual attestation reserved segment*)

    MARS 中包含了所有 enclave 的 mainfo 

  <img src="Mage_devlog_插图/image-20220212195012898.png" alt="image-20220212195012898" style="zoom:67%;" />

  - PREMR (*pre-measurement*)

  - MAINFO (*Mutual Attestation Information*)

    <img src="Mage_devlog_插图/image-20220212194659548.png" alt="image-20220212194659548" style="zoom:67%;" />

    字节数应该是为了方便索引找到对应 enclave 的 PREMR

    SECINFO 是每个 EPC Page 都有的，所以 MARS 页面也需要



- MAGE 组成部分

  - A SDK Library 

    - libsgx_mage

      为 MARS 保留  .sgx_mage 字段

      提供两个 API ：

      - sgx_mage_size

        返回 mainfo的数量

      - sgx_mage_gen_measurement

        生成某个 encalve 的 measurement

  - a modified enclave loader 

    > 因为默认情况下，会先加载 code,data 然后加载 TCS
    >
    > 而 .sgx_mage 属于 data 段，但他应该在最后被加载
    >
    > 所以需要修改加载顺序

  

  - modified signing tool

    原始的 signing tool 是 SDK 提供的，用于计算 measurement 

    > The signing tool simulates the loading process of the enclave to calculate the measurement before signing it.

    <img src="Mage_devlog_插图/image-20220212203354566.png" alt="image-20220212203354566" style="zoom:67%;" />

    - 签名的具体内容

      ![image-20220212204740435](Mage_devlog_插图/image-20220212204740435.png)





### 12.15

#### Done : 完成 SGX 环境的搭建

> https://github.com/intel/linux-sgx
>
> 按照官方的流程一步步来即可，多数是一些缺少库的小问题

- driver 

  > 如果 git clone 不下来，可以尝试将 https 换为 git，包括 .gitmodules 中的

- sdk

  **MAGE is implemented by extending the Intel SGX SDK**

  ![image-20211215204815866](Mage复现过程_插图/image-20211215204815866.png)

- psw 

  > 在 `make psw` 之前需要先安装好 sdk

  ![image-20211215204753278](Mage复现过程_插图/image-20211215204753278.png)

  - `-lpthread` 的问题

    > https://stackoverflow.com/questions/31948521/building-error-using-cmake-cannot-find-lpthreads
    >
    > 可能核心问题并不是它，我通过查找 `Error`，发现其实真正的问题在于 `crul`，安装一些库即可解决

- 测试样例





**关于 sdk 和 psw 的解释**

https://community.intel.com/t5/Intel-Software-Guard-Extensions/what-difference-on-sgx-psw-and-sgx-sdk/td-p/1134046



#### Done : Question

##### 虚拟机网络图标消失，网卡无 ip 解决方式

```shell
sudo service network-manager stop
sudo rm /var/lib/NetworkManager/NetworkManager.state
sudo service network-manager start

sudo netplan apply	
```







