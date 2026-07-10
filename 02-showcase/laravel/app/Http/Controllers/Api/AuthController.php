<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

final class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        // Password is hashed by the User model's 'hashed' cast — no explicit
        // Hash::make here (that would double-hash and break login).
        $user = User::create([
            'name'     => $request->validated('name'),
            'email'    => $request->validated('email'),
            'password' => $request->validated('password'),
        ]);

        return $this->tokenResponse($user, Response::HTTP_CREATED);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->validated('email'))->first();

        if ($user === null || ! Hash::check($request->validated('password'), $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['These credentials do not match our records.'],
            ]);
        }

        return $this->tokenResponse($user, Response::HTTP_OK);
    }

    public function me(): UserResource
    {
        return new UserResource(request()->user());
    }

    private function tokenResponse(User $user, int $status): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken('api')->plainTextToken,
            'user'  => new UserResource($user),
        ], $status);
    }
}
