import { test } from 'node:test';
import assert from 'node:assert';
import { greet, add } from '../index';

test('greet function', () => {
  assert.strictEqual(greet('World'), 'Hello, World!');
  assert.strictEqual(greet('TypeScript'), 'Hello, TypeScript!');
});

test('add function', () => {
  assert.strictEqual(add(2, 3), 5);
  assert.strictEqual(add(-1, 1), 0);
  assert.strictEqual(add(0, 0), 0);
});
