import { Quad } from '@rdfjs/types';

export interface ParseOptions {
  extendedSyntax?: boolean;
}

export declare function parse(str: string, options?: ParseOptions): Quad[];
