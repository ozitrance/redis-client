//
//  RedisClient.swift
//  RedisClient
//
//  Created by Valerio Mazzeo on 23/02/2017.
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

import Foundation
import Vapor

// MARK: - RedisClientError

public enum RedisClientError: Error {

    case invalidResponse(RedisClientResponse)
    case transactionAborted
    case enqueueCommandError
}

// MARK: - RedisClient

public protocol RedisClient {

    func execute(_ command: String, arguments: [String]?) throws -> Future<RedisClientResponse>

    @discardableResult
    func multi(_ commands: @escaping (RedisClient, RedisClientTransaction) throws -> Void) throws -> Future<[RedisClientResponse]>
}

// MARK: - Convenience Methods

public extension RedisClient {

    public func execute(_ command: String, arguments: String...) throws -> Future<RedisClientResponse> {
        return try self.execute(command, arguments: arguments)
    }
}

public extension RedisClient {

    @discardableResult
    public func get(_ key: String) throws -> Future<String?> {

        return try self.execute("GET", arguments: key).map(to: String?.self){
            response in
            
            switch response {
            case .string(let value):
                return value
            case .null:
                return nil
            default:
                throw RedisClientError.invalidResponse(response)
            }

            
        }

    }

    @discardableResult
    public func incr(_ key: String) throws -> Future<Int64> {

        return try self.execute("INCR", arguments: key).map(to: Int64.self){
            response in
            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }
            
            return result

        }

    }

    @discardableResult
    public func del(_ keys: String...) throws -> Future<Int64> {
        return try self.del(keys)
    }

    @discardableResult
    public func del(_ keys: [String]) throws -> Future<Int64> {

        return try self.execute("DEL", arguments: keys).map(to: Int64.self){
            response in

            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }

            return result
        }
    }

    @discardableResult
    public func lpush(_ key: String, values: String...) throws -> Future<Int64> {
        return try self.lpush(key, values: values)
    }

    @discardableResult
    public func lpush(_ key: String, values: [String]) throws -> Future<Int64> {

        var arguments = [key]
        arguments.append(contentsOf: values)

        return try self.execute("LPUSH", arguments: arguments).map(to: Int64.self){
            response in

            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }

            return result
        }
    }

    @discardableResult
    public func rpush(_ key: String, values: String...) throws -> Future<Int64> {
        return try self.rpush(key, values: values)
    }

    @discardableResult
    public func rpush(_ key: String, values: [String]) throws -> Future<Int64> {

        var arguments = [key]
        arguments.append(contentsOf: values)

        return try self.execute("RPUSH", arguments: arguments).map(to: Int64.self){
            response in

            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }

        return result
        }
    }

    @discardableResult
    public func rpoplpush(source: String, destination: String) throws -> Future<String?> {

        return try self.execute("RPOPLPUSH", arguments: [source, destination]).map(to: String?.self){
            response in

            switch response {
            case .string(let value):
                return value
            case .null:
                return nil
            default:
                throw RedisClientError.invalidResponse(response)
            }
        }
    }

    @discardableResult
    public func brpoplpush(source: String, destination: String, count: Int = 0) throws -> Future<String> {

        return try self.execute("BRPOPLPUSH", arguments: [source, destination, String(count)]).map(to: String.self){
            response in

            guard let result = response.string else {
                throw RedisClientError.invalidResponse(response)
            }

            return result
        }
    }

    public func setex(_ key: String, timeout: TimeInterval, value: String) throws {

        _ = try self.execute("SETEX", arguments: [key, String(Int(timeout)), value]).map(to: Void.self){
            response in
            
            guard response.status == .ok else {
                throw RedisClientError.invalidResponse(response)
            }
        }
    }

    @discardableResult
    public func lrem(_ key: String, value: String, count: Int? = nil) throws -> Future<Int64> {

        var arguments = [key]
        if let count = count {
            arguments.append(String(count))
        }
        arguments.append(value)

        return try self.execute("LREM", arguments: arguments).map(to: Int64.self){
            response in

            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }

            return result
        }
    }

    @discardableResult
    public func lrange(_ key: String, start: Int, stop: Int) throws -> Future<[String]> {

        return try self.execute("LRANGE", arguments: [key, String(start), String(stop)]).map(to: [String].self){
            response in

            guard let result = response.array else {
                throw RedisClientError.invalidResponse(response)
            }

            return result.flatMap { $0.string }
        }
    }

    @discardableResult
    public func zadd(_ key: String, values: (score: Double, member: String)...) throws -> Future<Int64> {
        return try self.zadd(key, values: values)
    }

    @discardableResult
    public func zadd(_ key: String, values: [(score: Double, member: String)]) throws -> Future<Int64> {

        var arguments = [key]

        for value in values {
            arguments.append(String(value.score))
            arguments.append(value.member)
        }

        return try self.execute("ZADD", arguments: arguments).map(to: Int64.self){
            response in

            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }

            return result
        }
    }

    @discardableResult
    public func zrange(_ key: String, start: Int, stop: Int) throws -> Future<[String]> {

        return try self.execute("ZRANGE", arguments: [key, String(start), String(stop)]).map(to: [String].self){
            response in

            guard let result = response.array else {
                throw RedisClientError.invalidResponse(response)
            }

            return result.flatMap { $0.string }
        }
    }

    @discardableResult
    public func zrangebyscore(_ key: String, min: Double, max: Double, includeMin: Bool = false, includeMax: Bool = true) throws -> Future<[String]> {

        var arguments = [key]

        let minArg = includeMin ? String(min) : "(\(min)"
        let maxArg = includeMax ? String(max) : "(\(max)"

        arguments.append(String(minArg))
        arguments.append(String(maxArg))

        return try self.execute("ZRANGEBYSCORE", arguments: arguments).map(to: [String].self){
            response in

            guard let result = response.array else {
                throw RedisClientError.invalidResponse(response)
            }

        return result.flatMap { $0.string }
        }
    }

    @discardableResult
    public func zrem(_ key: String, member: String) throws -> Future<Int64> {

        return try self.execute("ZREM", arguments: [key, member]).map(to: Int64.self){
            response in

            guard let result = response.integer else {
                throw RedisClientError.invalidResponse(response)
            }

            return result
        }
    }
}

// MARK: - Transactions

public struct RedisClientTransaction {

    public func enqueue(_ command: () throws -> Void) throws {
        do {
            try command()
            throw RedisClientError.enqueueCommandError
        } catch RedisClientError.invalidResponse(let response) {
            guard response.status == .queued else {
                throw RedisClientError.invalidResponse(response)
            }
        }
    }
}

public extension RedisClient {

    @discardableResult
    public func multi(_ commands: @escaping (RedisClient, RedisClientTransaction) throws -> Void) throws -> Future<[RedisClientResponse]> {

        return try self.execute("MULTI", arguments: nil).flatMap(to: [RedisClientResponse].self){
            response in

            guard response.status == .ok else {
                throw RedisClientError.invalidResponse(response)
            }

            do {
                try commands(self, RedisClientTransaction())
            } catch {
                _ = try self.execute("DISCARD", arguments: nil).map(to: RedisClientResponse.self){
                    response in
                    throw RedisClientError.transactionAborted

                }
            }

            return try self.execute("EXEC", arguments: nil).map(to: [RedisClientResponse].self){
                execResponse in
                
                guard let result = execResponse.array else {
                    throw RedisClientError.invalidResponse(response)
                }

                return result
            }
        }
    }
}
