// swift-tools-version:4.0

//
//  Package.swift
//  RedisClient
//
//  Created by Valerio Mazzeo on 21/02/2017.
//  Copyright © 2017 VMLabs Limited. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program. If not, see <http://www.gnu.org/licenses/>.
//

import PackageDescription

let package = Package(
	name: "RedisClient",
	products: [
		.library(name: "RedisClient", targets: ["RedisClient"])
	],
	dependencies: [
		.package(url: "git@github.com:ozitrance/pool.git", .branch("vapor3")),
		.package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "3.0.0-rc")),
	],
	targets: [
		.target(name: "RedisClient", dependencies: ["Pool", "Vapor"]),
		.testTarget(name: "RedisClientTests", dependencies: ["RedisClient"])
	]
)
