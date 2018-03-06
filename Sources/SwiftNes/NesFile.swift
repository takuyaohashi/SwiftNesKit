// 
// NesFile.swift
//
// Copyright © 2018 Takuya OHASHI. All rights reserved.
//
import Foundation

fileprivate let headerSize = 16
fileprivate let magicSize = 4

// MagicCode is placed in top of header
fileprivate func checkMagic(_ magic: Data) -> Bool {
	return (magic[0] == 0x4E &&
            magic[1] == 0x45 &&
            magic[2] == 0x53 &&
            magic[3] == 0x1A)
}

public struct NesFile {
	let Program: [UInt8]
	let Character: [UInt8]
    let programSize: Int
    let characterSize: Int

	private let programSizeUnit = 16 * 1024
	private let characterSizeUnit = 8 * 1024

	public init?(_ data: Data) {
		guard checkMagic(data.subdata(in: 0..<magicSize)) else {
			return nil
		}
		self.programSize = Int(data[4]) * programSizeUnit
		self.characterSize = Int(data[5]) * characterSizeUnit

        let programBottom = headerSize + programSize
		Program = [UInt8](data.subdata(in: headerSize..<programBottom))
		Character = [UInt8](data.subdata(in: programBottom..<(programBottom + characterSize)))
	}

    public func dumpAll() {
        dumpHeader()
        print("")
        dumpInstruction()
    }

    public func dumpInstruction() {
        print("## NES Program Section ##")

        let decoder = Decoder()
        let data = decoder.decodeAll(Program)
        var pc: UInt16 = 0x0

        for d in data {
            let inst = d.inst
            let value = d.value
            switch inst.addressing {
            case .ZeroPage, .Relative, .Absolute:
                print("\((pc+0x8000).hex): \(inst)  $\(value!.hex)")
            case .ZeroPageX, .AbsoluteX:
                print("\((pc+0x8000).hex): \(inst)  $\(value!.hex), X")
            case .ZeroPageY, .AbsoluteY:
                print("\((pc+0x8000).hex): \(inst)  $\(value!.hex), Y")
            case .Immediate:
                print("\((pc+0x8000).hex): \(inst) #$\(value!.hex)")
            case .Indirect:
                print("\((pc+0x8000).hex): \(inst)  ($\(value!.hex))")
            case .IndirectX:
                print("\((pc+0x8000).hex): \(inst)  ($\(value!.hex), X)")
            case .IndirectY:
                print("\((pc+0x8000).hex): \(inst)  ($\(value!.hex)), Y")
            default:
                print("\((pc+0x8000).hex): \(inst)")
            }
            pc = pc + (UInt16)(inst.bytes)
        }
    }

    public func dumpHeader() {
        print("## NES File Header Info ##")

        print("Program Size:   \(programSize) bytes")
        print("Character Size: \(characterSize) bytes")
    }
}
